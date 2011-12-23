require 'test_helper'

class TodoFilesControllerTest < ActionController::TestCase
  setup do
    @todo_file = todo_files(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:todo_files)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create todo_file" do
    assert_difference('TodoFile.count') do
      post :create, todo_file: @todo_file.attributes
    end

    assert_redirected_to todo_file_path(assigns(:todo_file))
  end

  test "should show todo_file" do
    get :show, id: @todo_file.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @todo_file.to_param
    assert_response :success
  end

  test "should update todo_file" do
    put :update, id: @todo_file.to_param, todo_file: @todo_file.attributes
    assert_redirected_to todo_file_path(assigns(:todo_file))
  end

  test "should destroy todo_file" do
    assert_difference('TodoFile.count', -1) do
      delete :destroy, id: @todo_file.to_param
    end

    assert_redirected_to todo_files_path
  end
end
