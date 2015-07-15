class Numeric
  def commify
    to_s.commify
  end
end

class String
  def commify
    gsub(/(\d)(?=(\d{3})+(\..*)?$)/,'\1,')
  end
end
