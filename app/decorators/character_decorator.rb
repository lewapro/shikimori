class CharacterDecorator < PersonDecorator
  instance_cache :seyu, :changes, :all_animes, :all_mangas, :cosplay?,
    :limited_animes, :limited_mangas, :top_seyu

  ROLES_PRIORITY = %w[Japanese English Other]

  def url
    h.character_url object
  end

  def top_seyu
    map_roles(
      person_roles
        .where(roles: %w[Japanese])
        .or(person_roles.where(roles: %w[English]))
    )
  end

  def all_seyu
    map_roles(person_roles.where.not(person_id: nil))
  end

  def job_title
    i18n_t(
      "job_title.#{'anime_' if animes.any?}#{'manga_' if mangas.any?}character"
    )
  end

  # презентер косплея
  def cosplay
    @cosplay ||= AniMangaPresenter::CosplayPresenter.new object, h
  end

  def animes limit = nil
    @animes ||= {}
    @animes[limit] ||= decorated_entries object.animes.limit(limit)
  end

  def mangas limit = nil
    @mangas ||= {}
    @mangas[limit] ||=
      decorated_entries object.mangas.where(type: Manga.name).limit(limit)
  end

  def ranobe limit = nil
    @ranobe ||= {}
    @ranobe[limit] ||=
      decorated_entries object.mangas.where(type: Ranobe.name).limit(limit)
  end

  # есть ли косплей
  def cosplay?
    CosplayGalleriesQuery.new(object).fetch(1, 1).any?
  end

private

  def map_roles person_roles_scope
    person_roles_scope
      .includes(:person)
      .sort_by do |person_role|
        [
          ROLES_PRIORITY.index(person_role.roles.first) ||
            ROLES_PRIORITY.size + 1,
          h.localized_name(person_role.person)
        ]
      end
      .map { |role| RoleEntry.new role.person, role.roles }
  end

  def decorated_entries query
    query
      .decorate
      .sort_by { |v| v.aired_on || v.released_on || Date.new(2001) }
  end
end
