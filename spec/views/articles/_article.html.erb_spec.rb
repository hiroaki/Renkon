require 'rails_helper'

RSpec.describe "articles/_article.html.erb", type: :view do
  let(:article) { FactoryBot.build(:article) }

  before do
    assign(:article, article)
  end

  context "when article description includes HTML tags" do
    it "sanitizes the description correctly" do
      article.description = "<script>alert('test');</script><p>This is a test description.</p>"
      render partial: "articles/article", locals: { article: article }

      expect(rendered).to include("This is a test description.")
      expect(rendered).not_to include("<script>")
      expect(rendered).to include("alert('test')")
    end
  end

  context "when article description includes allowed HTML tags" do
    it "removes disallowed HTML tags" do
      article.description = "<p>This is a <strong>test</strong> description.</p>"
      render partial: "articles/article", locals: { article: article }

      expect(rendered).to include("This is a test description.")
      expect(rendered).not_to include("<strong>")
    end
  end

  context "when article description includes allowed HTML tags" do
    it "retains allowed HTML tags" do
      article.description = "<p>This is a <strong>test</strong> description.</p>"
      render partial: "articles/article", locals: { article: article }

      expect(rendered).to include("This is a test description.")
      expect(rendered).to include("<p>")
      expect(rendered).not_to include("<strong>")
    end
  end

  context "when article description is plain text" do
    it "retains the plain text" do
      article.description = "This is a plain text description."
      render partial: "articles/article", locals: { article: article }

      expect(rendered).to include("This is a plain text description.")
    end
  end
end