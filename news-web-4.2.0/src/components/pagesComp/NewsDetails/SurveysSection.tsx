'use client'
import { useState } from 'react'
import { toast } from '@/lib/toast'
import { Progress } from '@/components/ui/progress'
import { Skeleton } from '@/components/ui/skeleton'
import { getSurveyResultApi, setSurveyResultApi } from '@/api/apiRoutes'
import { useGetSurveyQuestions, SurveyOptionApi } from '@/hooks/queries/useGetSurveyQuestions'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { isLogin } from '@/components/utils/helpers'
import SectionTitle from '@/components/common/SectionTitle'

const VISIBLE_SURVEYS = 2

const formatPercentage = (percentage?: string) => {
    const value = parseFloat(percentage ?? '0')
    if (isNaN(value)) return '0'
    return value % 1 === 0 ? String(value) : value.toFixed(2)
}

const SurveysSection = () => {

    const { t } = useTranslation()
    const langCode = useLangCode()

    const [selectedOptions, setSelectedOptions] = useState<Record<number, number>>({})
    const [results, setResults] = useState<Record<number, SurveyOptionApi[]>>({})
    const [submittingId, setSubmittingId] = useState<number | null>(null)

    const { data: surveysQueryData } = useGetSurveyQuestions({
        language_code: langCode,
        enabled: isLogin(),
    })

    const surveys = (surveysQueryData?.data?.data ?? []).slice(0, VISIBLE_SURVEYS)

    const handleSubmit = async (questionId: number) => {
        const optionId = selectedOptions[questionId]
        if (!optionId) {
            toast.error(t('optSel'))
            return
        }

        setSubmittingId(questionId)
        try {
            const response = await setSurveyResultApi({
                language_code: langCode,
                question_id: questionId,
                option_id: optionId,
            })
            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return
            }

            const resultResponse = await getSurveyResultApi({ language_code: langCode, question_id: questionId })
            const options = resultResponse?.data?.data?.[0]?.survey_options
            // An empty/failed result fetch must not be stored as a "0 option"
            // result — that renders as a permanently blank results block
            // instead of falling back to a retryable state.
            if (!options?.length) {
                toast.error(t('somethingMSg'))
                return
            }
            setResults((prev) => ({ ...prev, [questionId]: options }))
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
        } finally {
            setSubmittingId(null)
        }
    }

    if (!surveys.length) return null

    return (
        <>
            {surveys.map((survey) => {
                const answeredOptions = results[survey?.id]
                const isSubmitting = submittingId === survey?.id

                return (
                    <div className='survey flex flex-col gap-6 sm:gap-8 border borderColor rounded-xl p-4' key={survey?.id}>
                        <div className='[&_.sectionTitle]:mb-0! [&_.borderColor]:mt-4!'>
                            <SectionTitle title={survey?.question} showViewMore={false} />
                        </div>

                        {
                            isSubmitting ? (
                                <div className='flex flex-col gap-4'>
                                    {[...Array(survey?.survey_options?.length || 3)].map((_, index) => (
                                        <Skeleton key={index} height={30} />
                                    ))}
                                </div>
                            ) : answeredOptions ? (
                                <div className='answers flex flex-col gap-3'>
                                    {answeredOptions.map((option) => (
                                        <div className='relative' key={option?.id}>
                                            <Progress value={parseFloat(option?.percentage ?? '0')} className='h-10 commonRadius' />
                                            <span className='font-semibold text-white absolute inset-0 flexCenter text-[17px]'>
                                                {formatPercentage(option?.percentage)}%
                                            </span>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <>
                                    <div className='options flex flex-col gap-3'>
                                        {survey?.survey_options?.map((option) => (
                                            <span
                                                key={option?.id}
                                                className={`${selectedOptions[survey?.id] === option?.id ? 'primaryBg text-white border-none' : 'textPrimary'} border borderColor w-full p-3 rounded-lg text-center font-semibold text-[16px] sm:text-[18px] cursor-pointer`}
                                                onClick={() => setSelectedOptions((prev) => ({ ...prev, [survey.id]: option.id }))}
                                            >
                                                {option?.options}
                                            </span>
                                        ))}
                                    </div>
                                    <button className='secondaryBtn rounded-xl w-full text-[18px] sm:text-[20px] font-medium py-3 mb-1' onClick={() => handleSubmit(survey?.id)}>
                                        {t('submitBtn')}
                                    </button>
                                </>
                            )
                        }
                    </div>
                )
            })}
        </>
    )
}

export default SurveysSection
