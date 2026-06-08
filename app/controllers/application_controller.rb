class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionController::BadRequest, with: :render_bad_request
  rescue_from Llm::Client::Error, with: :render_ai_unavailable

  private

  # Resolve the current user from the Epico Bearer JWT (Authorization header).
  # The token carries `sub` (email) + `uuid` (resourceId); we match an existing
  # user by email and verify/backfill their Epico resource id.
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = resolve_current_user
  end

  def resolve_current_user
    claims = Auth::EpicoToken.decode(request.headers["Authorization"])
    user = User.find_by(email: claims.email)
    return (@auth_error = "no user for #{claims.email}") && nil unless user

    if user.epico_user_id.nil?
      user.update_column(:epico_user_id, claims.resource_id)
    elsif user.epico_user_id != claims.resource_id
      return (@auth_error = "token identity mismatch") && nil
    end
    user
  rescue Auth::EpicoToken::InvalidToken => e
    @auth_error = e.message
    nil
  end

  # before_action for endpoints that act on a user.
  def authenticate_user!
    return if current_user

    render_unauthorized(@auth_error || "authentication required")
  end

  def render_unauthorized(message)
    render_error(code: "unauthorized", message: message, status: :unauthorized)
  end

  def render_data(data, meta: {}, status: :ok)
    render json: { data: data, meta: meta }, status: status
  end

  def render_error(code:, message:, status:, details: nil)
    render json: {
      error: { code: code, message: message, details: details, request_id: request.request_id }
    }, status: status
  end

  def render_not_found(error)
    render_error(code: "not_found", message: error.message, status: :not_found)
  end

  def render_bad_request(error)
    render_error(code: "bad_request", message: error.message, status: :bad_request)
  end

  def render_ai_unavailable(error)
    render_error(code: "ai_unavailable", message: error.message, status: :bad_gateway)
  end

  def render_unprocessable(error)
    render_error(
      code: "validation_failed",
      message: "Validation failed",
      status: :unprocessable_entity,
      details: error.record.errors.map { |e| { field: e.attribute, message: e.message } }
    )
  end
end
