# frozen_string_literal: true

require_relative "click_funnels/version"
require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class ClickFunnels < OmniAuth::Strategies::OAuth2
      option :name, :click_funnels

      additional_options = if ENV["CLICK_FUNNELS_OAUTH_ROOT"] && Rails.env.development?
        {ssl: {verify: false}}
      else
        {}
      end

      option :client_options, {
        site: (ENV["CLICK_FUNNELS_OAUTH_ROOT"] || "https://accounts.myclickfunnels.com"),
        authorize_url: "/oauth/authorize"
      }.merge(additional_options)

      uid {
        raw_info.dig("id")
      }

      info do
        {
          # TODO I'm curious how many OAuth providers do this. Seems like most do. Is it part of the protocol?
          email: raw_info.dig("email")
        }.merge(raw_info)
      end

      def authorize_params
        super.tap do |params|
          %w[new_installation].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

      def raw_info
        @raw_info ||= JSON.parse(access_token.get("/api/v2/me").body)
      end

      # https://github.com/intridea/omniauth-oauth2/issues/81
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
