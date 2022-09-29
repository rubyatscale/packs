# typed: strict

class MyUserEventLogger < UsePackwerk::DefaultUserEventLogger
  extend T::Sig

  sig { params(pack_name: String).returns(String) }
  def before_create_pack(pack_name)
    <<~MSG
      You are creating a pack, which is great. Check out #{documentation_link} for more info!

      #{more_help_info}
    MSG
  end

  sig { params(pack_name: String).returns(String) }
  def before_move_to_pack(pack_name)
    <<~MSG
      You are moving a file to a pack, which is great. Check out #{documentation_link} for more info!

      #{more_help_info}
    MSG
  end

  sig { params(pack_name: String).returns(String) }
  def before_move_to_parent(pack_name)
    <<~MSG
      You are moving one pack to be a child of a different pack. Check out #{documentation_link} for more info!

      #{more_help_info}
    MSG
  end

  sig { returns(String) }
  def more_help_info
    <<~MSG
      Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
      We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
    MSG
  end

  sig { returns(String) }
  def documentation_link
    'https://go/packwerk'
  end
end

UsePackwerk.configure do |config|
  config.user_event_logger = MyUserEventLogger.new
end
