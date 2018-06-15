module ApplicationHelper

  CAP_TO_DESCRIPTIONS = {
    'accountNavigation' => 'Account Navigation',
    'courseNavigation' => 'Course Navigation',
    'assignmentSelection' => 'Assignment Selection',
    'linkSelection' => 'Link Selection'
  }

  def display_cap(cap)
    if CAP_TO_DESCRIPTIONS.keys.include? cap
      CAP_TO_DESCRIPTIONS[cap]
    else
      cap
    end
  end

  def log_div(seed, n)
    div = seed
    n.times do
      div += seed
    end
    div
  end

  def log_hash(h)
    logger.info log_div('*', 100)
    h.sort.map do |key, value|
      logger.info "#{key}: " + value
    end
    logger.info log_div('*', 100)
  end

end
