module ApplicationHelper
  def omniauth_provider?(code)
    provider = code.to_s
    OmniAuth::strategies.each do |strategy|
      puts strategy.to_s.demodulize.downcase
      return true if provider.downcase == strategy.to_s.demodulize.downcase
    end
    false
  end
end
