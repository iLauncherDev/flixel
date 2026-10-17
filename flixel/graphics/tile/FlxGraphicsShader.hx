package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexHeader("
		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
	", true)
	@:glVertexBody("
		openfl_Alphav = openfl_Alpha * alpha;

		if (hasColorTransform)
		{
			if (openfl_HasColorTransform)
			{
				openfl_ColorOffsetv = (openfl_ColorOffsetv * colorMultiplier) + (colorOffset / 255.0);
				openfl_ColorMultiplierv *= colorMultiplier;
			}
			else
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
	", true)
	@:glFragmentHeader("
		uniform bool hasTransform;  // TODO: Is this still needed? Apparently, yes!
		uniform bool hasColorTransform;
		uniform bool premultiplyAlpha;
		vec4 flixel_sampleBitmap(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);

			if (premultiplyAlpha)
				color.rgb *= color.a;

			if (!(hasTransform || openfl_HasColorTransform))
				return color;

			if (openfl_HasColorTransform || hasColorTransform)
			{
				color = vec4 (color.rgb / max(color.a, ALPHA_EPSILON), color.a);
				vec4 mult = vec4 (openfl_ColorMultiplierv.rgb, 1.0);
				color = clamp (openfl_ColorOffsetv + (color * mult), 0.0, 1.0);

				return vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}

			return color * openfl_Alphav;
		}

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			return openfl_applyBlend(flixel_sampleBitmap(bitmap, coord));
		}

		float flixel_texture2D_alpha(sampler2D bitmap, vec2 coord)
		{
			float alpha = texture2D(bitmap, coord).r;
			if (!(hasTransform || openfl_HasColorTransform))
				return alpha;

			if (openfl_HasColorTransform || hasColorTransform)
			{
				alpha = clamp (openfl_ColorOffsetv.a + alpha, 0.0, 1.0);
			}

			return alpha * openfl_Alphav;
		}
	", true)
	@:glFragmentSource("
		#define DEPTH_PASS_SUPPORTED
		#pragma header

		void main(void)
		{
		#ifdef DEPTH_PASS
			float alpha = flixel_texture2D_alpha(bitmap, openfl_TextureCoordv);
			DEPTH_ALPHA_CHECK(alpha);
			return;
		#endif

			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		}
	", true)
	public function new()
	{
		super();
	}
}
