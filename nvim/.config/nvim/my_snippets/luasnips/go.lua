-- https://www.youtube.com/watch?v=Dn800rlPIho&t
-- check for conditions of the return type
return {
	s(
		"iferr",
		fmt(
			[[
        if err != nil {{
          {}
        }}
      ]],
			-- do a-s-l to cycle choices
			{ c(1, { t("return err"), t("") }) }
		)
	),
}
