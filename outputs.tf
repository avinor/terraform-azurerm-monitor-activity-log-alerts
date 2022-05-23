output "id" {
  description = "Id of the action group."
  value       = values(azurerm_monitor_action_group.main).*.id
}
