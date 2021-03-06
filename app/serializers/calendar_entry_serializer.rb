class CalendarEntrySerializer < ActiveModel::Serializer
  attributes :next_episode, :next_episode_at, :duration
  has_one :anime

  def next_episode
    object.next_episode
  end

  def next_episode_at
    object.next_episode_start_at
  end

  def duration
    if object.next_episode_end_at && object.object.next_episode_start_at
      object.next_episode_end_at - object.object.next_episode_start_at
    elsif object.duration > 0
      object.duration * 60
    else
      nil
    end
  end
end
