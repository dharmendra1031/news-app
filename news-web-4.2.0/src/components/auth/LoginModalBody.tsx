'use client'
import { AnimatePresence, motion } from 'framer-motion'
import LoginForm from './LoginForm'
import RegisterForm from './RegisterForm'
import ForgotPasswordForm from './ForgotPasswordForm'
import PhoneLogin from './PhoneLogin'

interface LoginModalBodyProps {
  loginModal: boolean
  registerModal: boolean
  forgotPassModal: boolean
  phoneLogin: boolean
  mainModal: boolean
  setLoginModal: (value: boolean) => void
  setRegisterModal: (value: boolean) => void
  setForgotPassModal: (value: boolean) => void
  setPhoneLogin: (value: boolean) => void
  setIsLogout: (value: boolean) => void
  setMainModal: (value: boolean) => void
}

export default function LoginModalBody({
  loginModal,
  registerModal,
  forgotPassModal,
  phoneLogin,
  mainModal,
  setLoginModal,
  setRegisterModal,
  setForgotPassModal,
  setPhoneLogin,
  setIsLogout,
  setMainModal,
}: LoginModalBodyProps) {
  return (
    <div className="grid grid-cols-1">
      <AnimatePresence mode="wait" initial={false}>
        {loginModal && (
          <motion.div
            key="login"
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -16 }}
            transition={{ duration: 0.2 }}
          >
            <LoginForm
              setRegisterModal={setRegisterModal}
              setPhoneLogin={setPhoneLogin}
              setLoginModal={setLoginModal}
              setForgotPassModal={setForgotPassModal}
              setIsLogout={setIsLogout}
              setMainModal={setMainModal}
            />
          </motion.div>
        )}

        {registerModal && (
          <motion.div
            key="register"
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -16 }}
            transition={{ duration: 0.2 }}
          >
            <RegisterForm setLoginModal={setLoginModal} setRegisterModal={setRegisterModal} />
          </motion.div>
        )}

        {forgotPassModal && (
          <motion.div
            key="forgot"
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -16 }}
            transition={{ duration: 0.2 }}
          >
            <ForgotPasswordForm setForgotPassModal={setForgotPassModal} setLoginModal={setLoginModal} />
          </motion.div>
        )}

        {phoneLogin && (
          <motion.div
            key="phone"
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -16 }}
            transition={{ duration: 0.2 }}
          >
            <PhoneLogin setMainModal={setMainModal} mainModal={mainModal} />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
