module DashboardsHelper
    def active_klass(link_path)
        class_name = current_page?(link_path) ? 'active' : ''

        return class_name
    end
end
