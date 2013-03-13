require 'json'

module Grocer
  # Public: An object used to send notifications to APNS.
  class Notification
    MAX_PAYLOAD_SIZE = 2048
    CONTENT_AVAILABLE_INDICATOR = 1

    attr_accessor :identifier, :expiry, :device_token
    attr_reader :alert, :badge, :custom, :sound, :content_available, :category, :extra, :map, :hash, :data, :type, :private_group, :group, :conversation

    # Public: Initialize a new Grocer::Notification. You must specify at least an `alert` or `badge`.
    #
    # payload - The Hash of notification parameters and payload to be sent to APNS.:
    #           :device_token      - The String representing to device token sent to APNS.
    #           :alert             - The String or Hash to be sent as the alert portion of the payload. (optional)
    #           :badge             - The Integer to be sent as the badge portion of the payload. (optional)
    #           :sound             - The String representing the sound portion of the payload. (optional)
    #           :expiry            - The Integer representing UNIX epoch date sent to APNS as the notification expiry. (default: 0)
    #           :identifier        - The arbitrary Integer sent to APNS to uniquely this notification. (default: 0)
    #           :content_available - The truthy or falsy value indicating the availability of new content for background fetch. (optional)
    #           :category          - The String to be sent as the category portion of the payload. (optional)
    def initialize(payload = {})
      @identifier = 0

      payload.each do |key, val|
        send("#{key}=", val)
      end
    end

    def to_bytes
      validate_payload
      payload = encoded_payload

      [
        1,
        identifier,
        expiry_epoch_time,
        device_token_length,
        sanitized_device_token,
        payload.bytesize,
        payload
      ].pack('CNNnH64nA*')
    end

    def payload_too_large?
      encoded_payload.bytesize > MAX_PAYLOAD_SIZE
    end

    def truncate(field)
      field_val = send(field)
      field_size = field_val.bytesize
      payload_size = encoded_payload.bytesize
      max_field_size = MAX_PAYLOAD_SIZE - (payload_size - field_size)
      if max_field_size > 0
        field_val = field_val[0..max_field_size]
        send(field.to_s + "=", field_val)
      else
        send(field.to_s + "=", nil)
      end
    end

    private

    def payload_too_large?
      encoded_payload.bytesize > MAX_PAYLOAD_SIZE
    end

    def validate_payload
      fail NoPayloadError unless alert || badge
      fail PayloadTooLargeError if payload_too_large?
      true
    end

    def valid?
      validate_payload rescue false
    end

    private

    def validate_payload
      fail NoPayloadError unless alert || badge
      fail PayloadTooLargeError if payload_too_large?
    end

    def encoded_payload
      @encoded_payload ||= JSON.dump(payload_hash)
    end

    def payload_hash
      aps_hash = { }
      aps_hash[:alert] = alert if alert
      aps_hash[:badge] = badge if badge
      aps_hash[:sound] = sound if sound
      aps_hash[:'content-available'] = content_available if content_available?
      aps_hash[:category] = category if category
      aps_hash[:extra] = extra if extra
      aps_hash[:map] = map if map
      aps_hash[:hash] = hash if hash
      aps_hash[:data] = data if data
      aps_hash[:type] = type if type
      aps_hash[:private_group] = private_group if private_group
      aps_hash[:group] = group if group
      aps_hash[:conversation] = conversation if conversation
      aps_hash.merge(custom || {})
      { aps: aps_hash }
    end

      { aps: aps_hash }.merge(custom || { })
    end

    def expiry_epoch_time
      expiry.to_i
    end

    def sanitized_device_token
      device_token.tr(' ', '') if device_token
    end

    def device_token_length
      32
    end

    def alert= alert
      @alert = alert
      @encoded_payload = nil
    end

    def badge= badge
      @badge = badge
      @encoded_payload = nil
    end

    def sound= sound
      @sound = sound
      @encoded_payload = nil
    end
  end
end
