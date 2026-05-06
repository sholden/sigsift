class ScanRunTrace < ApplicationRecord
  belongs_to :scan_run

  MAX_BYTES = 1_000_000  # 1MB safety cap

  before_save :enforce_size_cap

  def messages
    return [] if messages_json.blank?
    JSON.parse(messages_json)
  rescue JSON::ParserError
    []
  end

  def metadata
    return {} if metadata_json.blank?
    JSON.parse(metadata_json)
  rescue JSON::ParserError
    {}
  end

  private

  def enforce_size_cap
    if messages_json.present? && messages_json.bytesize > MAX_BYTES
      truncated = messages_json[0, MAX_BYTES] + "...[truncated]"
      self.messages_json = truncated
    end
  end
end
