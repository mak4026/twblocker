require 'test_helper'
class TopControllerTest < ActionController::TestCase

  test 'check screen name regexp' do
    reg = TopController.new.send(:valid_id_regexp)
    assert reg.match("White_mak4026")
    assert reg.match("Twitter_JP")
    assert_not reg.match("ついったー")
  end

  test 'check twitter status url regexp' do
    reg = TopController.new.send(:valid_status_url_regexp)
    assert reg.match("http://twitter.com/White_mak4026/status/911049666254430208")
    assert reg.match("https://twitter.com/White_mak4026/status/911049666254430208")
    assert reg.match("https://twitter.com/White_mak4026/statuses/911049666254430208")
    assert_not reg.match("https://www.google.com/")

    reg_result = reg.match("https://twitter.com/White_mak4026/statuses/911049666254430208")

    assert_equal "White_mak4026", reg_result[1]
    assert_equal "911049666254430208", reg_result[2]
  end

  test 'expand url' do
    url = 'https://t.co/KtwGjTFqzk'
    expanded_url = TopController.new.send(:expand_url, url)
    assert_equal 'https://maktopia.hatenablog.com/', expanded_url

    direct_url = 'https://twitter.com/White_mak4026'
    assert_equal direct_url, TopController.new.send(:expand_url, direct_url)
  end
end
