class ListImports::Import
  method_object :list_import

  def call
    User.transaction { do_import }
  rescue ListImports::ParseFile::BrokenFileError
    specific_error ListImport::ERROR_BROKEN_FILE
  rescue StandardError => e
    exception_error e
  end

private

  def do_import
    list = ListImports::ParseFile.call(open(ListImport.last.list.path))

    if list.empty?
      specific_error ListImport::ERROR_EMPTY_LIST
    elsif wrong_list_type? list
      specific_error ListImport::ERROR_MISMATCHED_LIST_TYPE
    else
      import list
    end
  end

  def import list
    ListImports::ImportList.call @list_import, list

    @list_import.save!
    @list_import.finish!
  end

  def specific_error error_type
    @list_import.to_failed!
    @list_import.update! output: { error: { type: error_type } }
  end

  # rubocop:disable MethodLength
  def exception_error exception
    @list_import.to_failed!
    @list_import.update!(
      output: {
        error: {
          type: ListImport::ERROR_EXCEPTION,
          class: exception.class.name,
          message: exception.message,
          backtrace: exception.backtrace
        }
      }
    )
  end
  # rubocop:enable MethodLength

  def wrong_list_type? list
    list.any? do |list_entry|
      list_entry[:target_type].downcase != @list_import.list_type
    end
  end
end