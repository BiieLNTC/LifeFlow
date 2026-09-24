import { AuthApiError } from "@supabase/supabase-js";

/** Mesmas mensagens do app mobile — ver supabase_auth_repository.dart. */
export function authErrorMessage(error: unknown): string {
  if (error instanceof AuthApiError) {
    switch (error.code) {
      case "invalid_credentials":
        return "E-mail ou senha incorretos.";
      case "email_not_confirmed":
        return "Confirme seu e-mail antes de entrar.";
      case "user_already_exists":
        return "Já existe uma conta com este e-mail.";
      case "weak_password":
        return "Use uma senha com pelo menos 8 caracteres, letras e números.";
      case "over_request_rate_limit":
      case "over_email_send_rate_limit":
        return "Muitas tentativas. Aguarde alguns minutos e tente novamente.";
      case "signup_disabled":
        return "Novos cadastros estão temporariamente indisponíveis.";
      case "email_address_invalid":
        return "Informe um e-mail válido.";
      case "same_password":
        return "A nova senha deve ser diferente da senha atual.";
      case "session_not_found":
        return "Sua sessão expirou. Solicite um novo link.";
      default:
        return "Não foi possível concluir a autenticação. Tente novamente.";
    }
  }
  return "Não foi possível conectar ao serviço. Verifique sua internet e tente novamente.";
}
