class ListImport < ApplicationRecord
  include Translation

  ERROR_EXCEPTION = 'error_exception'
  ERROR_EMPTY_LIST = 'empty_list'
  ERROR_MISMATCHED_LIST_TYPE = 'mismatched_list_type'

  belongs_to :user

  enumerize :list_type,
    in: Types::ListImport::ListType.values,
    predicates: { prefix: true }

  enumerize :duplicate_policy,
    in: Types::ListImport::DuplicatePolicy.values,
    predicates: { prefix: true }

  state_machine :state, initial: :pending do
    state :finished
    state :failed

    event(:finish) { transition pending: :finished }
    event(:to_failed) { transition pending: :failed }
  end

  has_attached_file :list

  validates :user, presence: true
  validates_attachment :list,
    presence: true,
    content_type: {
      content_type: %w[
        application/xml
        application/json
        application/gzip
        text/plain
      ]
    }

  after_create :schedule_worker

  def name
    i18n_t 'name', id: id, filename: list_file_name
  end

  def empty_list_error?
    failed? && output&.dig('error', 'type') == ERROR_EMPTY_LIST
  end

  def mismatched_list_type_error?
    failed? && output&.dig('error', 'type') == ERROR_MISMATCHED_LIST_TYPE
  end

private

  def schedule_worker
    ListImports::Worker.perform_async id
  end
end
