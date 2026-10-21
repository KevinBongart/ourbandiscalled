require "rails_helper"

RSpec.feature "Generating an album" do
  before do
    stub_next_quote(body: "Nothing beats a great pair of shoes.")
    stub_wikipedia(title: "Test Band")
    stub_flickr
  end

  scenario "visiting the root hands the visitor a freshly generated album" do
    visit "/"

    expect(page).to have_css("h1", text: "Test Band")
    expect(page).to have_css("h2", text: "Great Pair Of Shoes")
    expect(page).to have_css("#by", text: "by")
  end

  scenario "the album is persisted at its own URL" do
    visit "/"

    expect(page).to have_current_path("/great-pair-of-shoes-by-test-band")
  end

  scenario "the cover art links back to the generator" do
    visit "/"

    expect(page).to have_css("#cover img[src='#{Record.last.cover}']")
    expect(page).to have_link(href: "/")
  end

  scenario "the footer credits all three sources" do
    visit "/"

    record = Record.last
    expect(page).to have_link("picture on Flickr", href: record.flickr_url)
    expect(page).to have_link("random Wikipedia page", href: record.wikipedia_url)
    expect(page).to have_link("random quote", href: record.quotationspage_url)
  end

  scenario "generating a second album from the first" do
    stub_wikipedia(pages: [ { id: 1, title: "First Band" }, { id: 2, title: "Second Band" } ])

    visit "/"
    expect(page).to have_css("h1", text: "First Band")

    click_link "Generate a new band"

    expect(page).to have_css("h1", text: "Second Band")
    expect(Record.count).to eq(2)
  end

  scenario "revisiting an album counts another view without regenerating it" do
    visit "/"
    slug = Record.last.slug

    # Landing on the album page via the root redirect is itself the first view.
    expect(Record.last.views).to eq(1)

    visit "/#{slug}"

    expect(Record.count).to eq(1)
    expect(Record.last.views).to eq(2)
  end
end
