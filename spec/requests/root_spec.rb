require "rails_helper"

RSpec.describe "root", :vcr do
  subject { get('/') }

  it "creates a new album" do
    expect(Record.count).to eq(0)

    subject

    expect(Record.count).to eq(1)
    record = Record.first

    expect(record.band).to eq 'General Stanton'
    expect(record.wikipedia_url).to eq 'http://en.wikipedia.org/wiki/General_Stanton'

    expect(record.title).to eq 'Let Them Scare You'
    expect(record.quotationspage_url).to eq 'http://www.quotationspage.com//quote/2559.html'

    # Record#set_album_cover uses Array#sample, so this test includes
    # everything that's in the creates_a_new_album.yml VCR cassette.
    expect(record.cover).to be_in %w(
      https://live.staticflickr.com/65535/52878248290_e0a6fe735d.jpg
      https://live.staticflickr.com/65535/52876917062_0047267662_n.jpg
      https://live.staticflickr.com/65535/52880477935_96c49d3a2c_w.jpg
      https://live.staticflickr.com/65535/52880262073_8c855ca5ff_w.jpg
      https://live.staticflickr.com/65535/52881373403_4a5ae55326_w.jpg
      https://live.staticflickr.com/65535/52879838189_596bff8b5c_w.jpg
      https://live.staticflickr.com/65535/52878407955_f3f6e91e1b_w.jpg
      https://live.staticflickr.com/65535/52878414141_bb55cd9a81_w.jpg
      https://live.staticflickr.com/65535/52880551393_8cdde6af5e_w.jpg
      https://live.staticflickr.com/65535/52879199102_23f6840cb5_n.jpg
      https://live.staticflickr.com/65535/52880090174_c2621fee8c_w.jpg
      https://live.staticflickr.com/65535/52878368235_207c1ab403.jpg
      https://live.staticflickr.com/65535/52877720123_2250ec3b4c_w.jpg
      https://live.staticflickr.com/65535/52881545943_e78aa1eb6a_w.jpg
      https://live.staticflickr.com/65535/52879903035_dbdda03e90_w.jpg
      https://live.staticflickr.com/65535/52877158616_d7b2fda49d_w.jpg
      https://live.staticflickr.com/65535/52878305485_289028965a_w.jpg
      https://live.staticflickr.com/65535/52877939602_ffede50c30_w.jpg
      https://live.staticflickr.com/65535/52880122010_a06163d98a_z.jpg
      https://live.staticflickr.com/65535/52876403157_11b300032b.jpg
      https://live.staticflickr.com/65535/52879955584_1dc230415f_w.jpg
      https://live.staticflickr.com/65535/52878484073_15fcbe0fa2_w.jpg
      https://live.staticflickr.com/65535/52880539440_13d4cf5cb0_w.jpg
      https://live.staticflickr.com/65535/52880205240_1b9eb8069d_n.jpg
      https://live.staticflickr.com/65535/52875726504_83ca286fd4_w.jpg
      https://live.staticflickr.com/65535/52878596679_dfe850f2c6_w.jpg
      https://live.staticflickr.com/65535/52876218128_83992582a5.jpg
      https://live.staticflickr.com/65535/52877887264_83f251af8c_z.jpg
      https://live.staticflickr.com/65535/52880249968_136f7d94fc_w.jpg
      https://live.staticflickr.com/65535/52877213512_04d713cd15_n.jpg
      https://live.staticflickr.com/65535/52877864293_bdc3b2471e_w.jpg
      https://live.staticflickr.com/65535/52879525282_694910c655_n.jpg
      https://live.staticflickr.com/65535/52878106096_0d9879a221_w.jpg
      https://live.staticflickr.com/65535/52880712830_9e4602fa1c_w.jpg
      https://live.staticflickr.com/65535/52877550223_92e9e9c405_n.jpg
      https://live.staticflickr.com/65535/52878413387_e042eab191.jpg
      https://live.staticflickr.com/65535/52876645611_7b782e37f2.jpg
      https://live.staticflickr.com/65535/52881012384_6dd173aff6_n.jpg
      https://live.staticflickr.com/65535/52879158957_9564a3a830_n.jpg
      https://live.staticflickr.com/65535/52877501116_e7bfa4ef8f.jpg
      https://live.staticflickr.com/65535/52879647011_c6e226bbaf_w.jpg
      https://live.staticflickr.com/65535/52876638589_70ef97f331_n.jpg
      https://live.staticflickr.com/65535/52879210527_37092fe49f_w.jpg
      https://live.staticflickr.com/65535/52879924233_347b56d95a.jpg
      https://live.staticflickr.com/65535/52876600446_55cfcba741_n.jpg
      https://live.staticflickr.com/65535/52879006067_f7eb12bd48_w.jpg
      https://live.staticflickr.com/65535/52876154683_1273a6bfc4_w.jpg
      https://live.staticflickr.com/65535/52878034280_366b45ca51_w.jpg
      https://live.staticflickr.com/65535/52879166617_9175ab0055_w.jpg
    )

    expect(record.flickr_url).to match /http\:\/\/flickr\.com\/photo\.gne\?id=\d+/

    expect(record.slug).to eq 'let-them-scare-you-by-general-stanton'
    expect(record.views).to eq 0
  end

  it 'redirects to the album page' do
    subject

    expect(response).to redirect_to('http://www.example.com/attribute-of-the-strong-by-dan-river-coalfield')
    follow_redirect!

    expect(response.body).to include('Attribute Of The Strong')
    expect(response.body).to include('Dan River Coalfield')
  end
end
