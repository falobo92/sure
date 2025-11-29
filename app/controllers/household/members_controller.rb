# frozen_string_literal: true

module Household
  class MembersController < Household::BaseController
    before_action :set_member, only: %i[edit update destroy]

    def index
      @members = Current.family.household_members.ordered
    end

    def new
      @member = Current.family.household_members.build
    end

    def create
      @member = Current.family.household_members.build(member_params)

      if @member.save
        redirect_to household_members_path, notice: "Miembro creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @member.update(member_params)
        redirect_to household_members_path, notice: "Miembro actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @member.destroy
      redirect_to household_members_path, notice: "Miembro eliminado exitosamente."
    end

    private

    def set_member
      @member = Current.family.household_members.find(params[:id])
    end

    def member_params
      params.require(:household_member).permit(:name, :code, :position)
    end
  end
end

