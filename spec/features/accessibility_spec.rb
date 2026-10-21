require "rails_helper"
require "axe-rspec"

RSpec.feature "Accessibility", js: true do
  before do
    stub_next_quote(body: "Nothing beats a great pair of shoes.")
    stub_wikipedia(title: "Test Band")
    stub_flickr
  end

  scenario "the generated album page has no axe violations" do
    visit "/"

    expect(page).to be_axe_clean
  end

  scenario "an album visited directly by slug has no axe violations" do
    visit "/"
    slug = Record.last.slug

    visit "/#{slug}"

    expect(page).to be_axe_clean
  end

  scenario "the album page meets WCAG 2.0 A and AA" do
    visit "/"

    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
  end

  scenario "the cover image and its link are both named" do
    visit "/"

    expect(page).to be_axe_clean.checking_only(:"image-alt", :"link-name")
  end

  scenario "page content sits inside landmarks" do
    visit "/"

    expect(page).to be_axe_clean.checking_only(:"landmark-one-main", :region, :"html-has-lang")
  end
end
