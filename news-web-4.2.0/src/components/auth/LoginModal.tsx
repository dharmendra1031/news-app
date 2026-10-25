'use client'
import { useEffect, useState } from 'react'
import dynamic from 'next/dynamic'
import {
  Dialog,
  DialogContent,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { BiUserCircle } from 'react-icons/bi'
import { MdOutlineClose } from 'react-icons/md'
import { useSelector } from 'react-redux'
import { loginModalOpenSelector } from '@/redux/reducers/helperSlice'
import { useTranslation } from '@/hooks/useTranslation'

// Animated form switcher pulls in framer-motion + firebase/auth — only load it once the modal is opened
const LoginModalBody = dynamic(() => import('./LoginModalBody'))

interface LoginModalProps {
  onClose?: () => void
}

export default function LoginModal({ onClose = () => {} }: LoginModalProps) {
  const { t } = useTranslation()

  const [mainModal, setMainModal] = useState(false)
  const [loginModal, setLoginModal] = useState(true)
  const [registerModal, setRegisterModal] = useState(false)
  const [phoneLogin, setPhoneLogin] = useState(false)
  const [forgotPassModal, setForgotPassModal] = useState(false)

  const [, setIsLogout] = useState(false)

  const isLoginModalOpen = useSelector(loginModalOpenSelector)

  const handleOpenLoginModal = () => {
    onClose()
    setLoginModal(true)
    setRegisterModal(false)
    setForgotPassModal(false)
    setPhoneLogin(false)
  }

  useEffect(() => {
    // Syncs the redux "open the login modal" flag (set elsewhere, e.g. a login-required
    // prompt) into this dialog's own local open state.
    if (isLoginModalOpen) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setMainModal(true)
    }
  }, [isLoginModalOpen])

  return (
    <Dialog open={mainModal} onOpenChange={setMainModal}>
      <DialogTrigger
        aria-label="Login"
        className="commonBtn flexCenter gap-2 loginModalTriggerBtn h-9"
        onClick={handleOpenLoginModal}
      >
        <BiUserCircle size={23} />
        {t('loginLbl')}
      </DialogTrigger>

      <DialogContent className="loginModal bodyBgColor h-full w-full! max-w-full! sm:h-max sm:w-150! lg:max-w-[60%] xl:h-[41rem]! p-0 overflow-hidden" showCloseButton={false}>
        {/* the dialog title is added just for removing the console warning */}
        <DialogTitle className="hidden"></DialogTitle>
        <span className="absolute top-6 ltr:right-4 rtl:left-4 cursor-pointer" onClick={() => setMainModal(false)}>
          <MdOutlineClose size={30} color="gray" />
        </span>
        <LoginModalBody
          loginModal={loginModal}
          registerModal={registerModal}
          forgotPassModal={forgotPassModal}
          phoneLogin={phoneLogin}
          mainModal={mainModal}
          setLoginModal={setLoginModal}
          setRegisterModal={setRegisterModal}
          setForgotPassModal={setForgotPassModal}
          setPhoneLogin={setPhoneLogin}
          setIsLogout={setIsLogout}
          setMainModal={setMainModal}
        />
      </DialogContent>
    </Dialog>
  )
}
