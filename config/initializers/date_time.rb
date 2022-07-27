class ActiveSupport::TimeWithZone
  def no_dst
    self.dst? ? self - 1.hour : self
  end
end