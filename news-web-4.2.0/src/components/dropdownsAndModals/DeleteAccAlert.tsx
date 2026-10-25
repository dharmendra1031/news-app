'use client'
import { PiWarningCircleFill } from 'react-icons/pi'
import { useTranslation } from '@/hooks/useTranslation'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'

interface DeleteAccAlertProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onConfirm: (e: React.MouseEvent) => void
}

const DeleteAccAlert = ({ open, onOpenChange, onConfirm }: DeleteAccAlertProps) => {
  const { t } = useTranslation()

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="bg-white">
        <AlertDialogHeader>
          <AlertDialogTitle className="flex items-center gap-2"><PiWarningCircleFill color="#faad14" size={24} />{t('deleteAcc')}</AlertDialogTitle>
        </AlertDialogHeader>
        <AlertDialogDescription>
          <div className="flex flex-col gap-1">
            <p className="font-medium">{t('deleteAccWarning')}</p>
            <li className="font-medium ltr:ml-4 rtl:mr-5" style={{ listStyle: 'disc' }}>{t('profileInfo')}</li>
            <li className="font-medium ltr:ml-4 rtl:mr-5" style={{ listStyle: 'disc' }}>{t('settings')}</li>
            <li className="font-medium ltr:ml-4 rtl:mr-5" style={{ listStyle: 'disc' }}>{t('associatedContent')}</li>
          </div>
        </AlertDialogDescription>
        <AlertDialogFooter>
          <AlertDialogCancel onClick={() => onOpenChange(false)}>{t('noLbl')}</AlertDialogCancel>
          <AlertDialogAction onClick={onConfirm}>{`${t('yesLbl')},${t('deleteTxt')}`}</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}

export default DeleteAccAlert
