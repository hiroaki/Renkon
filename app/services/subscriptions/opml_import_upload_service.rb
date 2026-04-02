module Subscriptions
  class OpmlImportUploadService
    def self.call(file:, max_bytes: OpmlInputValidator::DEFAULT_MAX_BYTES)
      new(file:, max_bytes:).call
    end

    def initialize(file:, max_bytes:)
      @file = file
      @max_bytes = max_bytes
    end

    def call
      validation = OpmlInputValidator.validate_upload(file: @file, max_bytes: @max_bytes)
      return validation unless validation[:ok]

      opml_text = @file.read(@max_bytes + 1)
      if opml_text.bytesize > @max_bytes
        return OpmlInputValidator.error(OpmlInputValidator.file_too_large_message(@max_bytes))
      end

      OpmlImportService.call(opml_text: opml_text)
    end
  end
end
