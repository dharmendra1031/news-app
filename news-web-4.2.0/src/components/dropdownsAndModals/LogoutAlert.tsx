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

interface LogoutAlertProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onConfirm: () => void
}

const LogoutAlert = ({ open, onOpenChange, onConfirm }: LogoutAlertProps) => {
  const { t } = useTranslation()

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="bg-white">
        <AlertDialogHeader>
          <AlertDialogTitle className="flex items-center gap-2"><PiWarningCircleFill color="#faad14" size={24} />{t('logoutLbl')}</AlertDialogTitle>
        </AlertDialogHeader>
        <AlertDialogDescription>
          {t('logoutTxt')}
        </AlertDialogDescription>
        <AlertDialogFooter>
          <AlertDialogCancel onClick={() => onOpenChange(false)}>{t('noLbl')}</AlertDialogCancel>
          <AlertDialogAction onClick={onConfirm}>{`${t('yesLbl')},${t('logout')}`}</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}

export default LogoutAlert
