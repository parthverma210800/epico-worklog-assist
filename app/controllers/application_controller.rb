class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  # Prototype auth shim: resolve the user from a header, else fall back to the
  # first seeded user. Epico replaces this with its real authentication.
  def current_user
    @current_user ||= User.find_by(id: request.headers["X-User-Id"]) || User.first
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

  def render_unprocessable(error)
    render_error(
      code: "validation_failed",
      message: "Validation failed",
      status: :unprocessable_entity,
      details: error.record.errors.map { |e| { field: e.attribute, message: e.message } }
    )
  end
end
