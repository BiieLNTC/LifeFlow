export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      attachments: {
        Row: {
          content_type: string
          created_at: string
          created_by: string
          deleted_at: string | null
          entity_id: string
          entity_type: string
          file_name: string
          file_size: number
          id: string
          storage_path: string
          vehicle_id: string
        }
        Insert: {
          content_type: string
          created_at?: string
          created_by?: string
          deleted_at?: string | null
          entity_id: string
          entity_type: string
          file_name: string
          file_size: number
          id: string
          storage_path: string
          vehicle_id: string
        }
        Update: {
          content_type?: string
          created_at?: string
          created_by?: string
          deleted_at?: string | null
          entity_id?: string
          entity_type?: string
          file_name?: string
          file_size?: number
          id?: string
          storage_path?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "attachments_entity_fk"
            columns: ["entity_id", "vehicle_id"]
            isOneToOne: false
            referencedRelation: "maintenances"
            referencedColumns: ["id", "vehicle_id"]
          },
          {
            foreignKeyName: "attachments_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "attachments_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      budgets: {
        Row: {
          category_id: string
          created_at: string
          deleted_at: string | null
          id: string
          limit_amount: number
          month: number
          updated_at: string
          user_id: string
          year: number
        }
        Insert: {
          category_id: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          limit_amount: number
          month: number
          updated_at?: string
          user_id?: string
          year: number
        }
        Update: {
          category_id?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          limit_amount?: number
          month?: number
          updated_at?: string
          user_id?: string
          year?: number
        }
        Relationships: [
          {
            foreignKeyName: "budgets_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "budgets_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_category"
            referencedColumns: ["category_id"]
          },
        ]
      }
      categories: {
        Row: {
          color: string | null
          created_at: string
          deleted_at: string | null
          description: string
          id: string
          purpose: string
          updated_at: string
          user_id: string
        }
        Insert: {
          color?: string | null
          created_at?: string
          deleted_at?: string | null
          description: string
          id?: string
          purpose?: string
          updated_at?: string
          user_id?: string
        }
        Update: {
          color?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string
          id?: string
          purpose?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      expenses: {
        Row: {
          amount: number
          category: string
          created_at: string
          deleted_at: string | null
          description: string
          expense_date: string
          id: string
          last_synced_at: string | null
          notes: string | null
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          amount: number
          category: string
          created_at?: string
          deleted_at?: string | null
          description: string
          expense_date: string
          id: string
          last_synced_at?: string | null
          notes?: string | null
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          amount?: number
          category?: string
          created_at?: string
          deleted_at?: string | null
          description?: string
          expense_date?: string
          id?: string
          last_synced_at?: string | null
          notes?: string | null
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "expenses_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "expenses_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      goal_contributions: {
        Row: {
          amount: number
          contribution_date: string
          created_at: string
          goal_id: string
          id: string
          transaction_id: string | null
        }
        Insert: {
          amount: number
          contribution_date: string
          created_at?: string
          goal_id: string
          id?: string
          transaction_id?: string | null
        }
        Update: {
          amount?: number
          contribution_date?: string
          created_at?: string
          goal_id?: string
          id?: string
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "goal_contributions_goal_id_fkey"
            columns: ["goal_id"]
            isOneToOne: false
            referencedRelation: "savings_goals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "goal_contributions_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "finance_top_expenses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "goal_contributions_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "finance_top_income"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "goal_contributions_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      maintenance_items: {
        Row: {
          category: string
          description: string
          id: string
          labor_amount: number
          maintenance_id: string
          next_replacement_date: string | null
          next_replacement_odometer: number | null
          part_amount: number
        }
        Insert: {
          category: string
          description: string
          id: string
          labor_amount?: number
          maintenance_id: string
          next_replacement_date?: string | null
          next_replacement_odometer?: number | null
          part_amount?: number
        }
        Update: {
          category?: string
          description?: string
          id?: string
          labor_amount?: number
          maintenance_id?: string
          next_replacement_date?: string | null
          next_replacement_odometer?: number | null
          part_amount?: number
        }
        Relationships: [
          {
            foreignKeyName: "maintenance_items_maintenance_id_fkey"
            columns: ["maintenance_id"]
            isOneToOne: false
            referencedRelation: "maintenances"
            referencedColumns: ["id"]
          },
        ]
      }
      maintenances: {
        Row: {
          created_at: string
          deleted_at: string | null
          id: string
          last_synced_at: string | null
          maintenance_date: string
          maintenance_type: string
          notes: string | null
          odometer: number
          total_amount: number
          updated_at: string
          vehicle_id: string
          workshop: string | null
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          id: string
          last_synced_at?: string | null
          maintenance_date: string
          maintenance_type: string
          notes?: string | null
          odometer: number
          total_amount?: number
          updated_at?: string
          vehicle_id: string
          workshop?: string | null
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          id?: string
          last_synced_at?: string | null
          maintenance_date?: string
          maintenance_type?: string
          notes?: string | null
          odometer?: number
          total_amount?: number
          updated_at?: string
          vehicle_id?: string
          workshop?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "maintenances_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "maintenances_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      people: {
        Row: {
          birth_date: string | null
          created_at: string
          deleted_at: string | null
          id: string
          name: string
          updated_at: string
          user_id: string
        }
        Insert: {
          birth_date?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          name: string
          updated_at?: string
          user_id?: string
        }
        Update: {
          birth_date?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          name?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      recurring_transactions: {
        Row: {
          amount: number
          category_id: string
          created_at: string
          day_of_month: number
          deleted_at: string | null
          description: string
          end_date: string | null
          id: string
          paused: boolean
          person_id: string | null
          start_date: string
          type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          category_id: string
          created_at?: string
          day_of_month: number
          deleted_at?: string | null
          description: string
          end_date?: string | null
          id?: string
          paused?: boolean
          person_id?: string | null
          start_date: string
          type: string
          updated_at?: string
          user_id?: string
        }
        Update: {
          amount?: number
          category_id?: string
          created_at?: string
          day_of_month?: number
          deleted_at?: string | null
          description?: string
          end_date?: string | null
          id?: string
          paused?: boolean
          person_id?: string | null
          start_date?: string
          type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recurring_transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recurring_transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_category"
            referencedColumns: ["category_id"]
          },
          {
            foreignKeyName: "recurring_transactions_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_person"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "recurring_transactions_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
      refuelings: {
        Row: {
          created_at: string
          deleted_at: string | null
          fuel_type: string
          full_tank: boolean
          gas_station: string | null
          id: string
          last_synced_at: string | null
          liters: number
          notes: string | null
          odometer: number
          refueling_date: string
          total_amount: number
          unit_price: number
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          fuel_type: string
          full_tank?: boolean
          gas_station?: string | null
          id: string
          last_synced_at?: string | null
          liters: number
          notes?: string | null
          odometer: number
          refueling_date: string
          total_amount: number
          unit_price: number
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          fuel_type?: string
          full_tank?: boolean
          gas_station?: string | null
          id?: string
          last_synced_at?: string | null
          liters?: number
          notes?: string | null
          odometer?: number
          refueling_date?: string
          total_amount?: number
          unit_price?: number
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "refuelings_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "refuelings_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      reminders: {
        Row: {
          created_at: string
          deleted_at: string | null
          description: string
          id: string
          last_synced_at: string | null
          origin_maintenance_id: string | null
          status: string
          target_date: string | null
          target_odometer: number | null
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          description: string
          id: string
          last_synced_at?: string | null
          origin_maintenance_id?: string | null
          status?: string
          target_date?: string | null
          target_odometer?: number | null
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          description?: string
          id?: string
          last_synced_at?: string | null
          origin_maintenance_id?: string | null
          status?: string
          target_date?: string | null
          target_odometer?: number | null
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reminders_origin_maintenance_fk"
            columns: ["origin_maintenance_id", "vehicle_id"]
            isOneToOne: false
            referencedRelation: "maintenances"
            referencedColumns: ["id", "vehicle_id"]
          },
          {
            foreignKeyName: "reminders_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "reminders_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      savings_goals: {
        Row: {
          created_at: string
          deleted_at: string | null
          id: string
          target_amount: number
          target_date: string | null
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          id?: string
          target_amount: number
          target_date?: string | null
          title: string
          updated_at?: string
          user_id?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          id?: string
          target_amount?: number
          target_date?: string | null
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      transactions: {
        Row: {
          amount: number
          category_id: string
          created_at: string
          deleted_at: string | null
          description: string
          id: string
          installment_group_id: string | null
          installment_index: number | null
          installment_total: number | null
          person_id: string | null
          source_id: string | null
          source_type: string | null
          transaction_date: string
          type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          category_id: string
          created_at?: string
          deleted_at?: string | null
          description: string
          id?: string
          installment_group_id?: string | null
          installment_index?: number | null
          installment_total?: number | null
          person_id?: string | null
          source_id?: string | null
          source_type?: string | null
          transaction_date: string
          type: string
          updated_at?: string
          user_id?: string
        }
        Update: {
          amount?: number
          category_id?: string
          created_at?: string
          deleted_at?: string | null
          description?: string
          id?: string
          installment_group_id?: string | null
          installment_index?: number | null
          installment_total?: number | null
          person_id?: string | null
          source_id?: string | null
          source_type?: string | null
          transaction_date?: string
          type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_category"
            referencedColumns: ["category_id"]
          },
          {
            foreignKeyName: "transactions_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_person"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "transactions_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
      trips: {
        Row: {
          created_at: string
          deleted_at: string | null
          end_odometer: number | null
          ended_at: string | null
          id: string
          purpose: string | null
          start_odometer: number
          started_at: string
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          end_odometer?: number | null
          ended_at?: string | null
          id?: string
          purpose?: string | null
          start_odometer: number
          started_at: string
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          end_odometer?: number | null
          ended_at?: string | null
          id?: string
          purpose?: string | null
          start_odometer?: number
          started_at?: string
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trips_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "trips_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicle_documents: {
        Row: {
          created_at: string
          deleted_at: string | null
          description: string
          expiry_date: string | null
          id: string
          issue_date: string | null
          type: string
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          description: string
          expiry_date?: string | null
          id?: string
          issue_date?: string | null
          type: string
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          description?: string
          expiry_date?: string | null
          id?: string
          issue_date?: string | null
          type?: string
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vehicle_documents_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "vehicle_documents_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicles: {
        Row: {
          active: boolean
          brand: string
          created_at: string
          current_odometer: number
          deleted_at: string | null
          fuel_type: string | null
          id: string
          last_synced_at: string | null
          license_plate: string | null
          manufacture_year: number | null
          model: string
          model_year: number | null
          nickname: string
          notes: string | null
          photo_path: string | null
          purchase_date: string | null
          purchase_price: number | null
          updated_at: string
          user_id: string
          vehicle_type: string
          version: string | null
        }
        Insert: {
          active?: boolean
          brand: string
          created_at?: string
          current_odometer?: number
          deleted_at?: string | null
          fuel_type?: string | null
          id?: string
          last_synced_at?: string | null
          license_plate?: string | null
          manufacture_year?: number | null
          model: string
          model_year?: number | null
          nickname: string
          notes?: string | null
          photo_path?: string | null
          purchase_date?: string | null
          purchase_price?: number | null
          updated_at?: string
          user_id?: string
          vehicle_type: string
          version?: string | null
        }
        Update: {
          active?: boolean
          brand?: string
          created_at?: string
          current_odometer?: number
          deleted_at?: string | null
          fuel_type?: string | null
          id?: string
          last_synced_at?: string | null
          license_plate?: string | null
          manufacture_year?: number | null
          model?: string
          model_year?: number | null
          nickname?: string
          notes?: string | null
          photo_path?: string | null
          purchase_date?: string | null
          purchase_price?: number | null
          updated_at?: string
          user_id?: string
          vehicle_type?: string
          version?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      budget_progress: {
        Row: {
          budget_id: string | null
          category_description: string | null
          category_id: string | null
          limit_amount: number | null
          month: number | null
          percentage: number | null
          spent_amount: number | null
          status: string | null
          user_id: string | null
          year: number | null
        }
        Relationships: [
          {
            foreignKeyName: "budgets_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "budgets_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_category"
            referencedColumns: ["category_id"]
          },
        ]
      }
      finance_monthly_evolution: {
        Row: {
          expense: number | null
          income: number | null
          month: string | null
        }
        Relationships: []
      }
      finance_top_expenses: {
        Row: {
          amount: number | null
          category_description: string | null
          category_id: string | null
          description: string | null
          id: string | null
          rank: number | null
          transaction_date: string | null
        }
        Relationships: [
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_category"
            referencedColumns: ["category_id"]
          },
        ]
      }
      finance_top_income: {
        Row: {
          amount: number | null
          category_description: string | null
          category_id: string | null
          description: string | null
          id: string | null
          rank: number | null
          transaction_date: string | null
        }
        Relationships: [
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_totals_by_category"
            referencedColumns: ["category_id"]
          },
        ]
      }
      finance_totals: {
        Row: {
          balance: number | null
          monthly_expense: number | null
          monthly_income: number | null
        }
        Relationships: []
      }
      finance_totals_by_category: {
        Row: {
          category_color: string | null
          category_description: string | null
          category_id: string | null
          total_amount: number | null
          transaction_count: number | null
          type: string | null
        }
        Relationships: []
      }
      finance_totals_by_person: {
        Row: {
          person_id: string | null
          person_name: string | null
          total_amount: number | null
          transaction_count: number | null
          type: string | null
        }
        Relationships: []
      }
      financial_entries: {
        Row: {
          amount: number | null
          category: string | null
          description: string | null
          entry_date: string | null
          id: string | null
          source: string | null
          vehicle_id: string | null
        }
        Relationships: []
      }
      notification_items: {
        Row: {
          due_date: string | null
          kind: string | null
          severity: string | null
          subtitle: string | null
          target_id: string | null
          target_type: string | null
          title: string | null
          vehicle_id: string | null
        }
        Relationships: []
      }
      refueling_details: {
        Row: {
          consumption_km_l: number | null
          created_at: string | null
          deleted_at: string | null
          fuel_type: string | null
          full_tank: boolean | null
          gas_station: string | null
          id: string | null
          last_synced_at: string | null
          liters: number | null
          notes: string | null
          odometer: number | null
          refueling_date: string | null
          total_amount: number | null
          unit_price: number | null
          updated_at: string | null
          vehicle_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "refuelings_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "refuelings_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      reminder_details: {
        Row: {
          created_at: string | null
          current_odometer: number | null
          deleted_at: string | null
          description: string | null
          id: string | null
          last_synced_at: string | null
          origin_maintenance_id: string | null
          remaining_days: number | null
          remaining_km: number | null
          status: string | null
          target_date: string | null
          target_odometer: number | null
          updated_at: string | null
          vehicle_id: string | null
          visual_status: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reminders_origin_maintenance_fk"
            columns: ["origin_maintenance_id", "vehicle_id"]
            isOneToOne: false
            referencedRelation: "maintenances"
            referencedColumns: ["id", "vehicle_id"]
          },
          {
            foreignKeyName: "reminders_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicle_dashboard"
            referencedColumns: ["vehicle_id"]
          },
          {
            foreignKeyName: "reminders_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicle_dashboard: {
        Row: {
          attention_count: number | null
          brand: string | null
          consumption_km_l: number | null
          cost_per_km: number | null
          current_odometer: number | null
          manufacture_year: number | null
          model: string | null
          model_year: number | null
          monthly_distance_km: number | null
          monthly_spending: number | null
          next_reminder_date: string | null
          next_reminder_description: string | null
          next_reminder_id: string | null
          next_reminder_odometer: number | null
          next_reminder_remaining_days: number | null
          next_reminder_remaining_km: number | null
          next_reminder_status: string | null
          nickname: string | null
          photo_path: string | null
          vehicle_id: string | null
          vehicle_type: string | null
          version: string | null
        }
        Relationships: []
      }
      vehicle_timeline: {
        Row: {
          amount: number | null
          category: string | null
          created_at: string | null
          event_id: string | null
          event_type: string | null
          occurred_on: string | null
          odometer: number | null
          secondary_text: string | null
          title: string | null
          vehicle_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      generate_due_recurring_transactions: { Args: never; Returns: number }
      get_or_create_vehicle_category: {
        Args: { p_user_id: string }
        Returns: string
      }
      reminder_urgency: {
        Args: {
          p_current_odometer: number
          p_reference_date: string
          p_target_date: string
          p_target_odometer: number
        }
        Returns: string
      }
      save_maintenance: {
        Args: {
          p_id: string
          p_items: Json
          p_maintenance_date: string
          p_maintenance_type: string
          p_notes: string
          p_odometer: number
          p_vehicle_id: string
          p_workshop: string
        }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const

