module AniManga
  OngoingToReleasedDays = 2

  def self.included klass
    klass.extend ClassMethods
  end

  def year
    aired_on ? aired_on.year : nil
  end

  # костыль от миграеции на 1.9.3
  def japanese
    self[:japanese] ? self[:japanese].map {|v| v.force_encoding('utf-8') } : []
  end

  def english
    self[:english] || []
  end

  # временный костыль после миграции на 1.9.3
  def synonyms
    self[:synonyms] ? self[:synonyms].map {|v| v.encode('utf-8', undef: :replace, invalid: :replace, replace: '') } : []
  end

  # если жанров слишком много, то оставляем только 6 основных
  def main_genres
    all_genres = genres.sort_by {|v| Genre::LongNameGenres.include?(v.english) ? 0 : v.id }
    return all_genres if genres.size <= 5

    selected_genres = genres.select(&:main?)

    all_genres.each do |genre|
      break if selected_genres.size > 5
      selected_genres << genre unless selected_genres.include? genre
    end

    selected_genres.sort_by {|v| Genre::LongNameGenres.include?(v.english) ? 0 : v.id }
  end

  # из списка студий/издателей аниме возвращает единственного настоящего
  ['studios', 'publishers'].each do |kind|
    define_method "real_#{kind}" do
      return [] if self.send(kind).empty?
      return self.send(kind).map {|v| v.real } if self.send(kind).size == 1
      @real_st_pub_cache ||= self.send(kind).map {|v| v.real }.select {|v| v.real? }
      @real_st_pub_cache.empty? ? [self.send(kind).first.real] : @real_st_pub_cache
    end
  end

  # есть ли оценка?
  def with_score?
    score > 1.0 && score < 9.9 && !anons?
  end

  module ClassMethods
    def keywords_for season, type, genres, studios, publishers
      keywords = []
      case type
        when 'tv'
          keywords << 'аниме сериалы'

        when 'novel'
          keywords << 'визуальные новеллы'

        when 'movie'
          keywords << 'полнометражные аниме'

        else
          keywords << (self == Anime ? 'аниме анимэ' : 'манга')
      end
      keywords << AniMangaSeason.title_for(season, self) if season
      if genres
        keywords << 'жанр'
        keywords << genres.map {|v| "#{v.english} #{v.russian}" }.join(' ')
      end
      if studios
        keywords << 'студия'
        keywords << studios.map(&:name).join(' ')
      end
      if publishers
        keywords << 'издатель'
        keywords << publishers.map(&:name).join(' ')
      end
      keywords << "список каталог база"

      keywords.join ' '
    end
  end
end
