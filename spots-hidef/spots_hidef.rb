require 'pixelart'



module Pixelart


class Vector   # holds a vector graphics image (in source)

  class Shape; end
  class Circle < Shape
    def initialize( cx, cy, r, fill: )
      @cx   = cx
      @cy   = cy
      @r    = r
      @fill = fill
    end

    def to_svg
      %Q{<circle cx="#{@cx}" cy="#{@cy}" r="#{@r}" fill="#{@fill}" />}
    end
  end

  def initialize( width, height, header: nil )
     @width  = width
     @height = height

     @header = header
     @shapes = []
  end

  def circle( cx:, cy:, r:, fill: )
     @shapes << Circle.new( cx, cy, r, fill: fill )
  end

  def to_svg
    buf = String.new('')

    if @header
      buf << "<!--\n"
      ## auto-indent lines by five (5) spaces for now
      @header.each_line do |line|
        buf << "     #{line}"
      end
      buf << "\n-->\n\n"
    end

    buf << %Q{<svg version="1.1" width="#{@width}" height="#{@height}" xmlns="http://www.w3.org/2000/svg">\n}
    @shapes.each do |shape|
       buf << "  #{shape.to_svg}\n"
    end
    buf << "</svg>"
    buf
  end

  def save( path )
    # step 1: make sure outdir exits
    outdir = File.dirname( path )
    FileUtils.mkdir_p( outdir )  unless Dir.exist?( outdir )

    # step 2: save
    File.open( path, 'w:utf-8' ) do |f|
      f.write( to_svg )
    end
  end
  alias_method :write, :save

end # class Vector



class Image

def spots_hidef( spot=10,
              spacing: 0,
              center: nil,
              radius: nil,
              background: nil,
              lightness: nil,
              odd: false )

  width =  @img.width*spot+(@img.width-1)*spacing
  height = @img.height*spot+(@img.height-1)*spacing

  ## puts "  #{width}x#{height}"


  min_center, max_center = center ? center : [0,0]
  min_radius, max_radius = radius ? radius : [0,0]

  background_color = background ? Color.parse( background ) : 0

  min_lightness, max_lightness = lightness ? lightness : [0.0,0.0]



  ## settings in a hash for "pretty printing" in comments
  settings = { spot: spot
             }

  settings[ :spacing ] = spacing  if spacing
  settings[ :center ]  = center  if center
  settings[ :radius ] = radius  if radius
  settings[ :background ] = background  if background
  settings[ :lightness ] = lightness  if lightness
  settings[ :odd ] = odd   if odd


  v = Vector.new( width, height, header: <<TXT )
generated by pixelart/v#{VERSION} on #{Time.now.utc}

spots_hidef with settings:
    #{settings.to_json}
TXT


    @img.width.times do |x|
      @img.height.times do |y|
         color = @img[ x, y ]

         if color == 0  ## transparent
           if background   ## change transparent to background
              color = background_color
           else
             next ## skip transparent
           end
         end


         if lightness
          ## todo/check: make it work with alpha too
          h,s,l = Color.to_hsl( color, include_alpha: false )

           h = h % 360    ## make sure h(ue) is always positive!!!

           ## note: rand() return between 0.0 and 1.0
           l_diff = min_lightness +
                     (max_lightness-min_lightness)*rand()

           lnew = [1.0, l+l_diff].min
           lnew = [0.0, lnew].max

           ## print " #{l}+#{l_diff}=#{lnew} "

           color = Color.from_hsl( h,
                                   [1.0, s].min,
                                   lnew )
         end

         ## note: return hexstring with leading #
         # e.g.    0 becomes #00000000
         #        and so on
         color_hex = Color.to_hex( color, include_alpha: true )

         cx_offset,
         cy_offset = if center  ## randomize (offset off center +/-)
                       [(spot/2 + min_center) + rand( max_center-min_center ),
                        (spot/2 + min_center) + rand( max_center-min_center )]
                     else
                       [spot/2,   ## center
                        spot/2]
                     end

         cx = x*spot + x*spacing + cx_offset
         cy = y*spot + y*spacing + cx_offset

         r = if radius ## randomize (radius +/-)
                    min_radius + rand( max_radius-min_radius )
             else
                    spot/2
             end


         cx += spot/2   if odd && (y % 2 == 1)  ## add odd offset

         v.circle( cx: cx, cy: cy, r: r, fill: color_hex )
      end
    end

   v
end


end # class Image
end # class Pixelart






ids = [88, 100, 180, 190]

ids.each do |id|
  punk = Image.read( "./i/punk-#{10000+id}.png" )

  punk_spots = punk.spots_hidef( 10 )
  punk_spots.save( "./i/punk-#{10000+id}_spots1.svg" )


  punk_spots = punk.spots_hidef( 5, spacing: 5,
                          center: [-1,1], radius: [3,6] )

  punk_spots.save( "./i/punk-#{10000+id}_spots3.svg" )


  punk_spots = punk.zoom( 2 ).spots_hidef( 5, spacing: 5,
                          center: [-1,1], radius: [3,6] )

  punk_spots.save( "./i/punk-#{10000+id}_spots3@2x.svg" )
end


puts "bye"