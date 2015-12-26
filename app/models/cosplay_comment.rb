class CosplayComment < AniMangaComment
  def title
    gallery_linked = linked.animes.first || linked.mangas.first ||
      linked.characters.first

    "Косплей #{gallery_linked.name}"
  end

  def text
    title
  end
end
