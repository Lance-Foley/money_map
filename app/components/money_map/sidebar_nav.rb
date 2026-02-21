# frozen_string_literal: true

module Components
  module MoneyMap
    class SidebarNav < Components::Base
      NAV_ITEMS = [
        { label: "Dashboard", path: :root_path, icon: :layout_dashboard },
        { label: "Budget", path: :budget_path, icon: :wallet },
        { label: "Action Plan", path: :action_plan_path, icon: :clipboard_list },
        { label: "Transactions", path: :transactions_path, icon: :arrow_left_right },
        { label: "Accounts", path: :accounts_path, icon: :landmark },
        { label: "Debt Payoff", path: :debts_path, icon: :trending_down },
        { label: "Savings & Goals", path: :savings_goals_path, icon: :piggy_bank },
        { label: "Recurring Bills", path: :recurring_bills_path, icon: :repeat },
        { label: "Reports", path: :reports_path, icon: :bar_chart_3 },
        { label: "Forecasting", path: :forecasts_path, icon: :line_chart },
        { label: "Settings", path: :settings_path, icon: :settings }
      ].freeze

      def initialize(current_page: "Dashboard")
        @current_page = current_page
      end

      def view_template
        Sidebar(side: :left, collapsible: :offcanvas) do
          SidebarHeader do
            div(class: "flex items-center gap-2 px-2 py-2") do
              div(class: "flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground") do
                money_icon
              end
              span(class: "text-lg font-semibold group-data-[collapsible=icon]:hidden") { "MoneyMap" }
            end
          end

          SidebarContent do
            SidebarGroup do
              SidebarGroupLabel { "Navigation" }
              SidebarGroupContent do
                SidebarMenu do
                  NAV_ITEMS.each do |item|
                    SidebarMenuItem do
                      SidebarMenuButton(as: :a, active: item[:label] == @current_page, href: helpers.send(item[:path])) do
                        send(:"#{item[:icon]}_icon")
                        span { item[:label] }
                      end
                    end
                  end
                end
              end
            end
          end

          SidebarFooter do
            div(class: "px-2 py-2 text-xs text-muted-foreground group-data-[collapsible=icon]:hidden") do
              plain "MoneyMap v1.0"
            end
          end

          SidebarRail
        end
      end

      private

      def money_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "18", height: "18", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.line(x1: "12", y1: "1", x2: "12", y2: "23")
          s.path(d: "M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6")
        end
      end

      def layout_dashboard_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.rect(x: "3", y: "3", width: "7", height: "9", rx: "1")
          s.rect(x: "14", y: "3", width: "7", height: "5", rx: "1")
          s.rect(x: "14", y: "12", width: "7", height: "9", rx: "1")
          s.rect(x: "3", y: "16", width: "7", height: "5", rx: "1")
        end
      end

      def wallet_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1")
          s.path(d: "M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4")
        end
      end

      def clipboard_list_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2")
          s.rect(x: "9", y: "3", width: "6", height: "4", rx: "1")
          s.path(d: "M9 14l2 2 4-4")
        end
      end

      def arrow_left_right_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M8 3 4 7l4 4")
          s.path(d: "M4 7h16")
          s.path(d: "m16 21 4-4-4-4")
          s.path(d: "M20 17H4")
        end
      end

      def landmark_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.line(x1: "3", y1: "22", x2: "21", y2: "22")
          s.line(x1: "6", y1: "18", x2: "6", y2: "11")
          s.line(x1: "10", y1: "18", x2: "10", y2: "11")
          s.line(x1: "14", y1: "18", x2: "14", y2: "11")
          s.line(x1: "18", y1: "18", x2: "18", y2: "11")
          s.polygon(points: "12 2 20 7 4 7")
        end
      end

      def trending_down_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.polyline(points: "22 17 13.5 8.5 8.5 13.5 2 7")
          s.polyline(points: "16 17 22 17 22 11")
        end
      end

      def piggy_bank_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M19 5c-1.5 0-2.8 1.4-3 2-3.5-1.5-11-.3-11 5 0 1.8 0 3 2 4.5V20h4v-2h3v2h4v-4c1-.5 1.7-1 2-2h2v-4h-2c0-1-.5-1.5-1-2")
          s.path(d: "M2 9.5c1.5 0 3-.5 3-2")
          s.path(d: "M15.5 9.5 14 11")
        end
      end

      def repeat_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "m17 2 4 4-4 4")
          s.path(d: "M3 11v-1a4 4 0 0 1 4-4h14")
          s.path(d: "m7 22-4-4 4-4")
          s.path(d: "M21 13v1a4 4 0 0 1-4 4H3")
        end
      end

      def bar_chart_3_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M3 3v18h18")
          s.path(d: "M18 17V9")
          s.path(d: "M13 17V5")
          s.path(d: "M8 17v-3")
        end
      end

      def line_chart_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M3 3v18h18")
          s.path(d: "m19 9-5 5-4-4-3 3")
        end
      end

      def settings_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16", height: "16", viewBox: "0 0 24 24",
          fill: "none", stroke: "currentColor", stroke_width: "2",
          stroke_linecap: "round", stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z")
          s.circle(cx: "12", cy: "12", r: "3")
        end
      end
    end
  end
end
