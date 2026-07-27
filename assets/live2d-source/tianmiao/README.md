# Tianmiao Live2D Source Package

This package is a Cubism production source kit, not a generated .moc3 model.

Generated layer PNGs:
- layers/HeadBase.png
- layers/FaceWhite.png
- layers/ForeheadStripes.png
- layers/CheekStripesL.png
- layers/CheekStripesR.png
- layers/Nose.png
- layers/MouthUpper.png
- layers/MouthInner.png
- layers/MouthTongue.png
- layers/WhiskersL.png
- layers/WhiskersR.png
- layers/EarL.png
- layers/EarR.png
- layers/EarInnerL.png
- layers/EarInnerR.png
- layers/EyeWhiteL.png
- layers/EyeWhiteR.png
- layers/PupilL.png
- layers/PupilR.png
- layers/EyeHighlightL.png
- layers/EyeHighlightR.png
- layers/EyelidUpperL.png
- layers/EyelidUpperR.png
- layers/EyelidLowerL.png
- layers/EyelidLowerR.png
- layers/BodyBase.png
- layers/ChestWhite.png
- layers/BackStripes.png
- layers/HipBase.png
- layers/FrontLegNear.png
- layers/FrontLegFar.png
- layers/FrontPawNear.png
- layers/FrontPawFar.png
- layers/HindLegNear.png
- layers/HindLegFar.png
- layers/HindPawNear.png
- layers/HindPawFar.png
- layers/TailRoot.png
- layers/TailMid.png
- layers/TailTip.png
- layers/TailStripes.png
- layers/GroundShadow.png

Important limitations:
- This is a production starting package for Cubism cleanup, not a final rig.
- Layer PNGs are auto-cropped from the currently selected cat identity and existing transparent rig parts.
- Small facial parts and overlap boundaries should be cleaned by a Cubism artist before mesh binding.
- Motion reference art is visual guidance only and must not replace the selected cat identity.

Generated previews:
- alpha/model-sheet.png
- alpha/motion-reference.png
- previews/layer-source-sheet.png
- previews/layer-source-sheet-on-white.jpg

Next step: import these layers into Live2D Cubism Editor/Modeler, clean mesh boundaries, bind parameters, and export tianmiao.model3.json, tianmiao.moc3, textures, and motion3 files.
