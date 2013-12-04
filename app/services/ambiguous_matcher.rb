class AmbiguousMatcher
  def initialize entries, options
    @entries = entries
    @options = options
  end

  def resolve
    entries = @entries
    entries = resolve_by_year entries, @options[:year] if @options[:year]
    entries = resolve_by_episodes entries, @options[:episodes] if @options[:episodes]
    entries
  end

private
  def resolve_by_year entries, year
    resolved = entries.select {|v| v.year == year }
    resolved.any? ? resolved : entries
  end

  def resolve_by_episodes entries, episodes
    range = episodes > 5 ? (episodes-episodes/10)..(episodes+episodes/10) : episodes..episdoes
    resolved = entries.select {|v| range.include? v.episodes }
    resolved.any? ? resolved : entries
  end
end
