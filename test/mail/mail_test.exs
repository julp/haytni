defmodule HaytniTestWeb.Haytni.TestEmails do
  def my_template_subject(_assigns) do
    "[SUBJECT] global"
  end

  def my_template_html(_assigns) do
    "[HTML] global"
  end

  def my_template_text(_assigns) do
    "[TEXT] global"
  end
end

defmodule HaytniTestWeb.Haytni.User.TestEmails do
  def my_template_subject(_assigns) do
    "[SUBJECT] scoped"
  end

  def my_template_html(_assigns) do
    "[HTML] scoped"
  end

  def my_template_text(_assigns) do
    "[TEXT] scoped"
  end
end

defmodule Hayni.MailTest do
#   import Haytni.Mail
  use HaytniWeb.EmailCase, [
    email: true,
  ]

  describe "Hayni.Mail" do
    @view HaytniTestWeb.Haytni.User.TestEmails
    @template "my_template"
    @expected_text "[TEXT] scoped"
    @expected_html "[HTML] scoped"
    @expected_subject "[SUBJECT] scoped"

    test "X" do
      Haytni.Mail.new()
#       |> Haytni.Mail.put_view()
    end

    test "html_body/2" do
      html = "Hello <b>World!</b>"
      mail = Haytni.Mail.new() |> Haytni.Mail.html_body(html)

      assert mail.text_body == nil
      assert mail.html_body == html
    end

    test "text_body/2" do
      text = "Hello World!"
      mail = Haytni.Mail.new() |> Haytni.Mail.text_body(text)

      assert mail.text_body == text
      assert mail.html_body == nil
    end

    test "put_text_template/3" do
      mail = Haytni.Mail.new() |> Haytni.Mail.put_text_template(@view, @template)

      assert mail.text_body == @expected_text
      assert mail.html_body == nil
    end

    test "put_html_template/3" do
      mail = Haytni.Mail.new() |> Haytni.Mail.put_html_template(@view, @template)

      assert mail.text_body == nil
      assert mail.html_body == @expected_html
    end

    test "put_template/3 (scoped)" do
      mail =
        Haytni.Mail.new()
        |> Haytni.Mail.put_view(@view)
        |> Haytni.Mail.put_template(@stack, @template)

      assert mail.subject == @expected_subject
      assert mail.text_body == @expected_text
      assert mail.html_body == @expected_html
    end

    test "put_template/4 (scoped)" do
      mail = Haytni.Mail.new() |> Haytni.Mail.put_template(@stack, "Test", @template)

      assert mail.subject == @expected_subject
      assert mail.text_body == @expected_text
      assert mail.html_body == @expected_html
    end

    test "put_template/4 (fallback to global)" do
      mail = Haytni.Mail.new() |> Haytni.Mail.put_template(HaytniTestWeb.HaytniAdmin, "Test", @template)

      assert mail.subject == "[SUBJECT] global"
      assert mail.text_body == "[TEXT] global"
      assert mail.html_body == "[HTML] global"
    end
  end
end
