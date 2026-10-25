declare module "*.png";
declare module "*.jpg";
declare module "*.jpeg";
declare module "*.svg";
declare module "*.gif";
declare module "*.webp";

// Phone-login OTP flow stashes its live reCAPTCHA verifier / confirmation
// result on `window` so they survive re-renders of OtpModal (see OtpModal.tsx).
import type { RecaptchaVerifier, ConfirmationResult } from "firebase/auth";

declare global {
    interface Window {
        recaptchaVerifier?: RecaptchaVerifier;
        confirmationResult?: ConfirmationResult;
    }
}

