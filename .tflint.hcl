plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}