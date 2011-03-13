require 'test_helper'

# This file contains test cases that override devise tests, in the cases that
# the difference is values from DM versus those expected by devise is not
# particularly important and getting DM to pass the original devise tests would
# be difficult.
#
# This file contains tests shared by both data_mapper and
# data_mapper_active_model ORM setups.
# Tests specific to the data_mapper orm which uses dm-validations are in dm_validations_test.rb
# Tests specific to the data_mapper_active_model orm which uses ActiveModel
# validations would be in active_model_test.rb, but there aren't any (I would
# be rather surprised if there ever were any).
#
# For each test, an explanation is given as to why I chose to override the test,
# and the original assertion is commented above the DM-specific assertion.

class TrackableHooksTest < ActionController::IntegrationTest

  undef test_current_and_last_sign_in_timestamps_are_updated_on_each_sign_in

  # DataMapper uses a DateTime type where ActiveRecord uses Time. The test is
  # that the tested properties are being set, so just check for kind_of?(DateTime)
  # instead of kind_of?(Time)
  test "current and last sign in timestamps are updated on each sign in" do
    user = create_user
    assert_nil user.current_sign_in_at
    assert_nil user.last_sign_in_at

    sign_in_as_user
    user.reload

    # assert_kind_of Time, user.current_sign_in_at
    # assert_kind_of Time, user.last_sign_in_at
    assert_kind_of DateTime, user.current_sign_in_at
    assert_kind_of DateTime, user.last_sign_in_at

    assert_equal user.current_sign_in_at, user.last_sign_in_at
    assert user.current_sign_in_at >= user.created_at

    visit destroy_user_session_path
    new_time = 2.seconds.from_now
    Time.stubs(:now).returns(new_time)

    sign_in_as_user
    user.reload
    assert user.current_sign_in_at > user.last_sign_in_at
  end
end

class DatabaseAuthenticatableTest < ActiveSupport::TestCase
  undef test_should_downcase_case_insensitive_keys_when_saving

  # save! is used in devise version of this test. In AR, save! runs callbacks
  # (and raises an error if any return false, which I assume is why its being
  # used). In DM, save! skips callbacks. Therefore, override and change #save!
  # to #save.
  test 'should downcase case insensitive keys when saving' do
    # case_insensitive_keys is set to :email by default.
    email = 'Foo@Bar.com'
    user = new_user(:email => email)

    assert_equal email, user.email
    user.save
    assert_equal email.downcase, user.email
  end
end

class AuthenticationRedirectTest < ActionController::IntegrationTest
  undef test_sign_in_with_xml_format_returns_xml_response

  # It appears DM's to_xml does not add the xml header
  test 'sign in with xml format returns xml response' do
    create_user
    post user_session_path(:format => 'xml', :user => {:email => "user@test.com", :password => '123456'})
    assert_response :success
    assert_match /\A<user>\s*<id/, response.body
  end
end
