# frozen_string_literal: true

module Components
  module MoneyMap
    class AppShell < Components::Base
      include Phlex::Rails::Helpers::Flash

      def initialize(current_page: "Dashboard", content: nil)
        @current_page = current_page
        @content = content
      end

      def view_template
        SidebarWrapper do
          render SidebarNav.new(current_page: @current_page)
          SidebarInset do
            # Top header bar with sidebar trigger
            header(class: "flex h-14 shrink-0 items-center gap-2 border-b px-4") do
              SidebarTrigger
              Separator(orientation: :vertical, class: "mr-2 !h-4")
              div(class: "flex-1")
              # Theme toggle in header
              ThemeToggle do
                SetLightMode do
                  Button(variant: :ghost, size: :sm, icon: true) do
                    sun_icon
                  end
                end
                SetDarkMode do
                  Button(variant: :ghost, size: :sm, icon: true) do
                    moon_icon
                  end
                end
              end
            end

            # Flash messages
            flash_div

            # Main content area - render captured content
            if @content
              raw(safe(@content))
            end
          end
        end
      end

      private

      def flash_div
        return if flash.blank?

        div(class: "px-4 pt-4 space-y-2") do
          flash.each do |type, message|
            next if message.blank?

            variant = case type.to_s
            when "notice", "success" then :success
            when "alert", "error" then :destructive
            when "warning" then :warning
            end

            Alert(variant: variant) do
              AlertDescription { message }
            end
          end
        end
      end

      def sun_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.circle(cx: "12", cy: "12", r: "4")
          s.path(d: "M12 2v2")
          s.path(d: "M12 20v2")
          s.path(d: "m4.93 4.93 1.41 1.41")
          s.path(d: "m17.66 17.66 1.41 1.41")
          s.path(d: "M2 12h2")
          s.path(d: "M20 12h2")
          s.path(d: "m6.34 17.66-1.41 1.41")
          s.path(d: "m19.07 4.93-1.41 1.41")
        end
      end

      def moon_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z")
        end
      end
    end
  end
end
