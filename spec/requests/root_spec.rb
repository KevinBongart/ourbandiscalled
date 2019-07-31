require "rails_helper"

RSpec.describe "root", :vcr do
  subject { get('/') }

  it "creates a new album" do
    expect(Record.count).to eq(0)

    subject

    expect(Record.count).to eq(1)
    record = Record.first

    expect(record.band).to eq 'Anatol Arhire'
    expect(record.wikipedia_url).to eq 'http://en.wikipedia.org/wiki/Anatol_Arhire'

    expect(record.title).to eq 'Be Conscious Of None'
    expect(record.quotationspage_url).to eq 'http://www.quotationspage.com//quote/26826.html'

    # Record#set_album_cover uses Array#sample, so this test includes
    # everything that's in the creates_a_new_album.yml VCR cassette.
    expect(record.cover).to be_in %w(
      https://live.staticflickr.com/65535/48409547982_358f462311_z.jpg
      https://live.staticflickr.com/65535/48409554962_ff78efa2a2_n.jpg
      https://live.staticflickr.com/65535/48409632152_7f980bc60b.jpg
      https://live.staticflickr.com/65535/48409640422_b5bfcf6fab.jpg
      https://live.staticflickr.com/65535/48409677487_09e7c02750.jpg
      https://live.staticflickr.com/65535/48409781786_ebf4d6e1af.jpg
      https://live.staticflickr.com/65535/48409816107_e60b688c35.jpg
      https://live.staticflickr.com/65535/48409851701_6a0c903daa.jpg
      https://live.staticflickr.com/65535/48410117717_38e002b090.jpg
      https://live.staticflickr.com/65535/48410508502_2cd9f0c2b7_n.jpg
      https://live.staticflickr.com/65535/48410777536_baa43c3146.jpg
      https://live.staticflickr.com/65535/48411290051_3dcab59ef1.jpg
      https://live.staticflickr.com/65535/48411399951_df142bb9ed_z.jpg
      https://live.staticflickr.com/65535/48411565867_ae995006a1.jpg
      https://live.staticflickr.com/65535/48411570856_c0c52af93b.jpg
      https://live.staticflickr.com/65535/48411579006_8bfc101959.jpg
      https://live.staticflickr.com/65535/48411582437_5cb91ca732.jpg
      https://live.staticflickr.com/65535/48411739987_2e234f0ffd.jpg
      https://live.staticflickr.com/65535/48411753897_4a059a493a.jpg
      https://live.staticflickr.com/65535/48411766941_c68235421f.jpg
      https://live.staticflickr.com/65535/48411833047_559fceb96c.jpg
      https://live.staticflickr.com/65535/48412007992_7b4b1a2ca5.jpg
      https://live.staticflickr.com/65535/48412113861_27d745c95e_n.jpg
      https://live.staticflickr.com/65535/48412128456_70e074a43b_n.jpg
      https://live.staticflickr.com/65535/48412265436_6ca54b32fd.jpg
      https://live.staticflickr.com/65535/48412402131_b0ede11380.jpg
      https://live.staticflickr.com/65535/48412442952_a513d7fe83.jpg
      https://live.staticflickr.com/65535/48412566902_934de51d52_n.jpg
      https://live.staticflickr.com/65535/48412771177_0825d9cd87_n.jpg
      https://live.staticflickr.com/65535/48413050051_b8b4dda874.jpg
      https://live.staticflickr.com/65535/48413100016_25904048b1.jpg
      https://live.staticflickr.com/65535/48413415457_9b03dffcbd_z.jpg
      https://live.staticflickr.com/65535/48413587577_c1c28d1031.jpg
      https://live.staticflickr.com/65535/48413618612_f694013941.jpg
      https://live.staticflickr.com/65535/48414032336_375f89b784_z.jpg
      https://live.staticflickr.com/65535/48414425861_0faacdceaa.jpg
      https://live.staticflickr.com/65535/48414475557_da08a5f201.jpg
      https://live.staticflickr.com/65535/48415214866_1db94574a0_z.jpg
      https://live.staticflickr.com/65535/48415550897_20e23c3e9b.jpg
      https://live.staticflickr.com/65535/48415602796_37d048827d.jpg
      https://live.staticflickr.com/65535/48415738892_cbb9bd82f6.jpg
      https://live.staticflickr.com/65535/48415868336_b2ed021851_n.jpg
      https://live.staticflickr.com/65535/48416118612_30f235f9be.jpg
      https://live.staticflickr.com/65535/48416802162_69b181db38_c.jpg
      https://live.staticflickr.com/65535/48416896912_70c46b215b.jpg
      https://live.staticflickr.com/65535/48416921011_f87574d4be_z.jpg
      https://live.staticflickr.com/65535/48417306026_b85bfb7644.jpg
      https://live.staticflickr.com/65535/48417356966_7b1654cf10_z.jpg
    )

    expect(record.flickr_url).to match /http\:\/\/flickr\.com\/photo\.gne\?id=\d+/

    expect(record.slug).to eq 'be-conscious-of-none-by-anatol-arhire'
    expect(record.views).to eq 0
  end

  it 'redirects to the album page' do
    subject

    expect(response).to redirect_to('http://www.example.com/go-but-enemies-accumulate-by-phascus-reticulaticollis')
    follow_redirect!

    expect(response.body).to include('Go, But Enemies Accumulate')
    expect(response.body).to include('Phascus Reticulaticollis')
  end
end
