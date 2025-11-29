# frozen_string_literal: true

require "test_helper"

module Household
  class MemberTest < ActiveSupport::TestCase
    setup do
      @family = families(:dylan_family)
    end

    test "creates member with valid attributes" do
      member = @family.household_members.build(
        name: "Carlos",
        code: "CL",
        position: 3
      )

      assert member.save
      assert_equal "Carlos", member.name
      assert_equal "CL", member.code
    end

    test "requires name" do
      member = @family.household_members.build(code: "XX")
      assert_not member.valid?
      assert_includes member.errors[:name], "can't be blank"
    end

    test "requires code" do
      member = @family.household_members.build(name: "Test")
      assert_not member.valid?
      assert_includes member.errors[:code], "can't be blank"
    end

    test "code must be unique within family" do
      @family.household_members.create!(name: "First", code: "AA", position: 1)

      duplicate = @family.household_members.build(name: "Second", code: "AA")
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:code], "has already been taken"
    end

    test "code is limited to 10 characters" do
      member = @family.household_members.build(
        name: "Test",
        code: "VERYLONGCODE"
      )
      assert_not member.valid?
      assert_includes member.errors[:code], "is too long (maximum is 10 characters)"
    end

    test "display_name combines name and code" do
      member = @family.household_members.build(name: "Felipe", code: "FL")
      assert_equal "Felipe (FL)", member.display_name
    end

    test "sets default position on create" do
      member = @family.household_members.create!(name: "Test", code: "TT")
      assert_equal 1, member.position

      member2 = @family.household_members.create!(name: "Test2", code: "T2")
      assert_equal 2, member2.position
    end
  end
end

