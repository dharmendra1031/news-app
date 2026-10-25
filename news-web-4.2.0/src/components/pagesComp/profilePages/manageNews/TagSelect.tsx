'use client'
import { useMemo, useState } from 'react'
import { FaAngleDown, FaCheck } from 'react-icons/fa6'
import { Button } from '@/components/ui/button'
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandList, CommandItem } from '@/components/ui/command'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'
import { useTranslation } from '@/hooks/useTranslation'
import { TagApi } from '@/hooks/queries/useGetTags'

type CreatableTag = TagApi | { id: number | string; tag_name: string }

interface TagSelectProps {
    tagsData: TagApi[]
    defaultTag?: string | null
    defaultTagName?: string | null
    handleTagChange: (values: string[], tagIds: (number | string)[]) => void
    onCreateTag: (name: string) => Promise<CreatableTag | string | void>
    onCreateError?: (error: unknown) => void
    onLoadMore?: () => void
    hasMore?: boolean
}

const TagSelect = ({
    tagsData,
    defaultTag,
    defaultTagName,
    handleTagChange,
    onCreateTag,
    onCreateError,
    onLoadMore,
    hasMore,
}: TagSelectProps) => {
    const { t } = useTranslation()
    const [open, setOpen] = useState(false)
    const [selectedValues, setSelectedValues] = useState<string[]>(defaultTagName?.split(',').filter(Boolean) || [])
    const [selectedTagIds, setSelectedTagIds] = useState<(number | string)[]>(defaultTag ? defaultTag.split(',') : [])

    const [query, setQuery] = useState('')
    const [localCreatedTags, setLocalCreatedTags] = useState<CreatableTag[]>([])
    const [isCreating, setIsCreating] = useState(false)
    const [createError, setCreateError] = useState('')

    const allTags = useMemo(() => {
        const list = [...localCreatedTags, ...(tagsData || [])]
        const seen = new Set<string>()
        return list.filter((tag) => {
            const name = (tag?.tag_name || '').trim()
            if (!name) return false
            const key = name.toLowerCase()
            if (seen.has(key)) return false
            seen.add(key)
            return true
        })
    }, [tagsData, localCreatedTags])

    const normalize = (s?: string | null) => (s || '').trim()
    const findExistingByName = (name: string) => {
        const key = normalize(name).toLowerCase()
        return allTags.find((tag) => normalize(tag?.tag_name).toLowerCase() === key)
    }

    const handleMultiSelectChange = (value: string, tagId?: number | string | null) => {
        let newValues: string[]
        let newIds: (number | string)[]

        if (selectedValues.includes(value)) {
            newValues = selectedValues.filter((v) => v !== value)
            newIds = selectedTagIds.filter((_, idx) => selectedValues[idx] !== value)
        } else {
            newValues = [...selectedValues, value]
            const resolvedId = tagId ?? findExistingByName(value)?.id
            newIds = [...selectedTagIds, resolvedId].filter((id): id is number | string => id !== undefined && id !== null)
        }

        setSelectedValues(newValues)
        setSelectedTagIds(newIds)
        handleTagChange(newValues, newIds)
    }

    const createAndSelectTag = async (rawName: string) => {
        const name = normalize(rawName)
        if (!name) return

        setCreateError('')

        const existing = findExistingByName(name)
        if (existing?.tag_name) {
            handleMultiSelectChange(existing.tag_name, existing.id)
            setQuery('')
            return
        }

        setIsCreating(true)
        try {
            const created = await onCreateTag(name)
            const createdName = typeof created === 'string' ? created : (created?.tag_name || name)
            const createdId = (typeof created === 'object' && created?.id) || `local-${createdName}`

            setLocalCreatedTags((prev) => [...prev, { id: createdId, tag_name: createdName }])
            handleMultiSelectChange(createdName, createdId)
            setQuery('')
        } catch (error: any) {
            const message = error?.message || error?.response?.data?.message || t('failedToCreateTag')

            if (/already exists/i.test(message)) {
                const maybeExisting = findExistingByName(name)
                if (maybeExisting?.tag_name) {
                    handleMultiSelectChange(maybeExisting.tag_name, maybeExisting.id)
                    setQuery('')
                }
            }
            setCreateError(message)
            onCreateError?.(error)
        } finally {
            setIsCreating(false)
        }
    }

    const onInputKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key !== 'Enter') return
        e.preventDefault()
        if (isCreating) return
        createAndSelectTag(query)
    }

    return (
        <Popover open={open} onOpenChange={setOpen}>
            <PopoverTrigger
                render={
                    <Button
                        variant='outline'
                        role='combobox'
                        aria-expanded={open}
                        className={`w-full justify-between h-10.5 customBgWhite ${selectedValues.length > 0 ? 'text-black hover:text-black' : 'text-gray-400 font-medium! hover:text-gray-400'}`}
                    >
                        <span>{selectedValues.length > 0 ? selectedValues.join(', ') : t('tagLbl')}</span>
                        <FaAngleDown className='h-3! w-3!' />
                    </Button>
                }
            />

            <PopoverContent className='w-(--anchor-width) max-w-full min-w-full p-0'>
                <Command className='w-full min-w-full!'>
                    <CommandInput
                        placeholder='Search tags...'
                        className='min-w-full!'
                        value={query}
                        onValueChange={(v) => {
                            setQuery(v)
                            if (createError) setCreateError('')
                        }}
                        onKeyDown={onInputKeyDown}
                        disabled={isCreating}
                    />

                    <CommandList onMouseLeave={() => setOpen(false)}>
                        <CommandEmpty>
                            <div className='py-2 text-sm text-muted-foreground'>
                                {t('noTagsFound')}
                                {normalize(query) ? (
                                    <div className='mt-1 text-red-500 font-semibold'>
                                        {t('press')} <span className='font-medium'>{t('enter')}</span> {t('toCreate')} {normalize(query)}
                                        {isCreating ? ` ${t('creating')}` : ''}
                                    </div>
                                ) : null}
                                {createError ? <div className='mt-2 text-sm text-red-600'>{createError}</div> : null}
                            </div>
                        </CommandEmpty>

                        <CommandGroup>
                            {allTags?.map((elem) => (
                                <CommandItem key={elem?.id} value={elem?.tag_name} onSelect={() => handleMultiSelectChange(elem?.tag_name, elem?.id)}>
                                    <FaCheck className={cn('mr-2 h-4 w-4', selectedValues.includes(elem?.tag_name) ? 'opacity-100' : 'opacity-0')} />
                                    {elem?.tag_name}
                                </CommandItem>
                            ))}
                            {hasMore && (
                                <div className='p-2 text-center'>
                                    <Button variant='link' size='sm' onClick={() => onLoadMore?.()}>
                                        {t('loadMore')}
                                    </Button>
                                </div>
                            )}
                        </CommandGroup>
                    </CommandList>
                </Command>
            </PopoverContent>
        </Popover>
    )
}

export default TagSelect
