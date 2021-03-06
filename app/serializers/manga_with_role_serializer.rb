class MangaWithRoleSerializer < MangaSerializer
  attribute :roles do
    object.roles
  end

  attribute :role do
    object.roles.join(', ')
  end
end
