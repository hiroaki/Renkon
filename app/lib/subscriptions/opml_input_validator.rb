module Subscriptions
  class OpmlInputValidator
    DEFAULT_MAX_BYTES = 2.megabytes

    def self.validate_upload(file:, max_bytes: DEFAULT_MAX_BYTES)
      return error('Please choose an OPML file.') unless file.respond_to?(:read)

      if file.respond_to?(:size) && file.size.to_i > max_bytes
        return error(file_too_large_message(max_bytes))
      end

      filename = file.respond_to?(:original_filename) ? file.original_filename.to_s : ''
      unless filename.downcase.end_with?('.opml', '.xml')
        return error('Please upload an .opml or .xml file.')
      end

      sample = file.read(2048)
      file.rewind if file.respond_to?(:rewind)

      return error('The file is empty.') if sample.blank?
      return error('The file appears to be binary. Please upload a text OPML/XML file.') if sample.b.include?("\x00".b)

      return error('The file does not look like OPML/XML content.') unless opml_like_header?(sample)

      ok
    end

    def self.validate_text(opml_text:, max_bytes: DEFAULT_MAX_BYTES)
      text = opml_text.to_s

      return error('The file is empty.') if text.strip.empty?
      return error(file_too_large_message(max_bytes)) if text.bytesize > max_bytes
      return error('The file appears to be binary. Please upload a text OPML/XML file.') if text.b.include?("\x00".b)

      return error('The file does not look like OPML/XML content.') unless opml_like_header?(text)

      ok
    end

    def self.file_too_large_message(max_bytes)
      "The OPML file is too large (max #{max_bytes / 1.megabyte}MB)."
    end

    def self.ok
      { ok: true }
    end

    def self.error(message)
      {
        ok: false,
        error: message,
        created_subscriptions: 0,
        created_groups: 0,
        skipped_subscriptions: 0,
        invalid_subscriptions: 0,
      }
    end

    def self.opml_like_header?(raw_text)
      normalized = raw_text.to_s.b.delete_prefix("\xEF\xBB\xBF".b).lstrip
      normalized.start_with?('<?xml'.b, '<opml'.b)
    end
  end
end
