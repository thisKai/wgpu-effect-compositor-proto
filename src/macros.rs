macro_rules! EnumShaderConstants {
    (
        $(
            #[$($attr:tt)*]
        )*
        $vis:vis enum $Enum:ident {
            $(
                $Variant:ident $(= $value:tt)?,
            )*
        }
    ) => {
        $(
            #[$($attr)*]
        )*
        #[derive(Copy, Clone, Debug, bytemuck::NoUninit, bytemuck::CheckedBitPattern)]
        #[repr(u32)]
        $vis enum $Enum {
            $(
                $Variant $(= $value)?,
            )*
        }

        impl $crate::macros::EnumShaderConstants for $Enum {
            const SHADER_CONSTANTS: &'static [(&'static str, f64)] = &[
                $(
                    (stringify!($Variant), Self::$Variant as u32 as f64),
                )*
            ];
        }
    };
}
pub trait EnumShaderConstants {
    const SHADER_CONSTANTS: &'static [(&'static str, f64)];
}
