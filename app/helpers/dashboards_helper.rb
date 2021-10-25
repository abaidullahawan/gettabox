module DashboardsHelper
  def active_klass(link_path)
    current_page?(link_path) ? 'active' : ''
  end
end
