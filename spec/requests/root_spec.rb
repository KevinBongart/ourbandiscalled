require "rails_helper"

RSpec.describe "root", :vcr do
  subject { get('/') }

  it "creates a new album" do
    expect(Record.count).to eq(0)

    subject

    expect(Record.count).to eq(1)
    record = Record.first

    expect(record.band).to eq 'Robert Helpmann'
    expect(record.wikipedia_url).to eq 'http://en.wikipedia.org/wiki/Robert_Helpmann'

    expect(record.title).to eq 'See Them Being Made'
    expect(record.quotationspage_url).to eq 'http://www.quotationspage.com//quote/27759.html'

    # Record#set_album_cover uses Array#sample, so this test includes
    # everything that's in the creates_a_new_album.yml VCR cassette.
    expect(record.cover).to be_in %w(
      https://live.staticflickr.com/65535/49240472563_1f42ec675e_w.jpg
      https://live.staticflickr.com/65535/49240619138_fdcc157827_n.jpg
      https://live.staticflickr.com/65535/49240640218_86886e9b9d_w.jpg
      https://live.staticflickr.com/65535/49240708962_9c0252e4e4.jpg
      https://live.staticflickr.com/65535/49240892322_710034e166_w.jpg
      https://live.staticflickr.com/65535/49240979957_d7d7c203a5_w.jpg
      https://live.staticflickr.com/65535/49241020551_ddf11c3cab.jpg
      https://live.staticflickr.com/65535/49241247256_aee3ba54eb_w.jpg
      https://live.staticflickr.com/65535/49241339326_a1904a4901_w.jpg
      https://live.staticflickr.com/65535/49241446703_71f7dfc04d.jpg
      https://live.staticflickr.com/65535/49241638468_2643e6527b_z.jpg
      https://live.staticflickr.com/65535/49241686341_91243e1699.jpg
      https://live.staticflickr.com/65535/49241710628_2d5a0000b6.jpg
      https://live.staticflickr.com/65535/49241715543_154de0b989.jpg
      https://live.staticflickr.com/65535/49241774991_cd74d00eb3.jpg
      https://live.staticflickr.com/65535/49241846953_a479fc4dd0_w.jpg
      https://live.staticflickr.com/65535/49241911077_033c762e64_n.jpg
      https://live.staticflickr.com/65535/49241980876_c2eaa8380c_n.jpg
      https://live.staticflickr.com/65535/49242017631_83e50e8f0c_z.jpg
      https://live.staticflickr.com/65535/49242051753_1c522a16c0.jpg
      https://live.staticflickr.com/65535/49242051782_84fd0ec82a_w.jpg
      https://live.staticflickr.com/65535/49242121573_16966bc712_n.jpg
      https://live.staticflickr.com/65535/49242135642_e8e78db33e_m.jpg
      https://live.staticflickr.com/65535/49242163571_c13895de73_w.jpg
      https://live.staticflickr.com/65535/49242742546_5d8e91790c_z.jpg
      https://live.staticflickr.com/65535/49242745071_d476132f73_z.jpg
      https://live.staticflickr.com/65535/49242796626_7624426de9_w.jpg
      https://live.staticflickr.com/65535/49242838238_2c0455c976_w.jpg
      https://live.staticflickr.com/65535/49242878477_7753eee095.jpg
      https://live.staticflickr.com/65535/49242917763_aeded6d99f_n.jpg
      https://live.staticflickr.com/65535/49242921836_669b9e39f1.jpg
      https://live.staticflickr.com/65535/49242934326_dac24e3047_w.jpg
      https://live.staticflickr.com/65535/49243070666_60d276a9ec.jpg
      https://live.staticflickr.com/65535/49243231463_d0b7e2eff9_n.jpg
      https://live.staticflickr.com/65535/49243251876_00d33b4fc6_w.jpg
      https://live.staticflickr.com/65535/49243506647_d8f9e35a10.jpg
      https://live.staticflickr.com/65535/49243516301_d45eb33cd5_w.jpg
      https://live.staticflickr.com/65535/49243590082_3abeb8b35c_w.jpg
      https://live.staticflickr.com/65535/49243672792_ecf3d5f49a.jpg
      https://live.staticflickr.com/65535/49243711311_9fbafb3d3a_z.jpg
      https://live.staticflickr.com/65535/49243754351_bfacf31668_w.jpg
      https://live.staticflickr.com/65535/49243822632_7074f2920a_z.jpg
      https://live.staticflickr.com/65535/49244078056_0813dc03f2_w.jpg
      https://live.staticflickr.com/65535/49244162611_f247a3d64e.jpg
      https://live.staticflickr.com/65535/49244212327_4d9458e055.jpg
    )

    expect(record.flickr_url).to match /http\:\/\/flickr\.com\/photo\.gne\?id=\d+/

    expect(record.slug).to eq 'see-them-being-made-by-robert-helpmann'
    expect(record.views).to eq 0
  end

  it 'redirects to the album page' do
    subject

    expect(response).to redirect_to('http://www.example.com/and-thought-is-viscous-by-saphenista-incauta')
    follow_redirect!

    expect(response.body).to include('And Thought Is Viscous<')
    expect(response.body).to include('Saphenista Incauta')
  end
end
