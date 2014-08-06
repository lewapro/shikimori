class AnimesController < ShikimoriController
  respond_to :html, only: [:show, :tooltip, :related_all]
  respond_to :json, only: :autocomplete
  respond_to :html, :json, only: :page

  before_action :authenticate_user!, only: [:edit]
  before_action :fetch_resource
  before_action :breadcrumbs, if: -> { @resource }
  before_action :check_redirect, if: -> { @resource }

  caches_action :page, :characters, :show, :related_all, :cosplay, :tooltip,
    cache_path: proc {
      id = params[:anime_id] || params[:manga_id] || params[:id]
      @resource ||= klass.find(id.to_i)
      "#{klass.name}|#{Digest::MD5.hexdigest params.to_json}|#{@resource.updated_at.to_i}|#{@resource.thread.updated_at.to_i}|#{json?}|v3|#{request.xhr?}"
    },
    unless: proc { user_signed_in? },
    expires_in: 2.days

  # отображение аниме или манги
  def show
    @itemtype = @resource.itemtype
  end

  def characters
    noindex
  end

  def files
    raise ActionController::RoutingError unless user_signed_in?
  end

  def similar
    noindex
  end

  def screenshots
    noindex
  end

  def videos
    noindex
  end

  def chronology
  end

  def images
  end

  def recent
  end


  # все связанные элементы с аниме/мангой
  def related_all
    render partial: 'animes/related_all', formats: :html unless @director.redirected?
  end

  # все связанные элементы с аниме/мангой
  def other_names
    render partial: 'animes/other_names', formats: :html
  end

  # редактирование аниме
  def edit
    show
    render :show unless @director.redirected?
  end

  # подстраница косплея
  def cosplay
    show
    render :show unless @director.redirected?
  end

  # торренты к эпизодам аниме
  def episode_torrents
    @resource = klass.find(params[:id].to_i).decorate
    render json: @resource.files.episodes_data
  end

  # тултип
  def tooltip
    @resource = klass.find params[:id].to_i
    direct
  end

  # автодополнение
  def autocomplete
    @items = AniMangaQuery.new(klass, params, current_user).complete
  end

  # rss лента новых серий и сабов аниме
  def rss
    anime = Anime.find(params[:id].to_i)

    case params[:type]
      when 'torrents'
        data = anime.torrents
        title = "Торренты #{anime.name}"

      when 'torrents_480p'
        data = anime.torrents_480p
        title = "Серии 480p #{anime.name}"

      when 'torrents_720p'
        data = anime.torrents_720p
        title = "Серии 720p #{anime.name}"

      when 'torrents_1080p'
        data = anime.torrents_1080p
        title = "Серии 1080p #{anime.name}"

      when 'subtitles'
        if anime.subtitles.include? params[:group]
          data = anime.subtitles[params[:group]][:feed].reverse
        else
          data = []
        end
        title = "Субтитры #{anime.name}"
    end

    feed = RSS::Maker.make("2.0") do |feed|
      feed.channel.title = title
      feed.channel.link = request.url
      feed.channel.description = "%s, найденные сайтом." % title
      feed.items.do_sort = true # sort items by date

      data.select {|v| v[:title] }.reverse.each do |item|
        entry = feed.items.new_item

        entry.title = item[:title].html_safe
        entry.link = item[:link].html_safe
        entry.description = "Seeders: %d, Leechers: %d" % [item[:seed], item[:leech]] if item[:seed] || item[:leech]
        entry.date = item[:pubDate] != nil ? Time.at(item[:pubDate].to_i) : Time.now
      end
    end

    response.headers['Content-Type'] = 'application/rss+xml; charset=utf-8'
    render text: feed
  end

private
  # класс текущего элемента
  def klass
    @klass ||= Object.const_get(self.class.name.underscore.split('_')[0].singularize.camelize)
  end

  def fetch_resource
    @resource = klass.find(resource_id.to_i).decorate if resource_id
  end

  # хлебные крошки
  def breadcrumbs
    if @resource.anime?
      breadcrumb 'Список аниме', animes_url
      breadcrumb 'Сериалы', animes_url(type: @resource.kind) if @resource.kind == 'TV'
      breadcrumb 'Полнометражные', animes_url(type: @resource.kind) if @resource.kind == 'Movie'
    else
      breadcrumb 'Список манги', mangas_url
    end

    if @resource.aired_on && [Time.zone.now.year + 1, Time.zone.now.year, Time.zone.now.year - 1].include?(@resource.aired_on.year)
      breadcrumb "#{@resource.aired_on.year} год", send("#{@resource.object.class.name.downcase.pluralize}_url", season: @resource.aired_on.year)
    end

    if @resource.genres.any?
      breadcrumb UsersHelper.localized_name(@resource.main_genre, current_user), send("#{@resource.object.class.name.downcase.pluralize}_url", genre: @resource.main_genre.to_param)
    end
  end

  ## часть заголовка с названием текущего элемента
  #def entry_title
    #"#{@resource.russian_kind} #{HTMLEntities.new.decode(@resource.name)}"
  #end
end
