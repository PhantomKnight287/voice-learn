export type Voice = {
  voice_id: string;
  name: string;
  samples: any;
  category: string;
  fine_tuning: {
    is_allowed_to_fine_tune: boolean;
    finetuning_state: string;
    verification_failures: Array<any>;
    verification_attempts_count: number;
    manual_verification_requested: boolean;
    language: any;
    finetuning_progress: Record<string, any>;
    message: any;
    dataset_duration_seconds: any;
    verification_attempts: any;
    slice_ids: any;
    manual_verification: any;
  };
  labels: {
    accent: string;
    description: string;
    age: string;
    gender: string;
    'use case': string;
  };
  description: any;
  preview_url: string;
  available_for_tiers: Array<any>;
  settings: any;
  sharing: any;
  high_quality_base_model_ids: Array<any>;
  safety_control: any;
  voice_verification: {
    requires_verification: boolean;
    is_verified: boolean;
    verification_failures: Array<any>;
    verification_attempts_count: number;
    language: any;
    verification_attempts: any;
  };
  owner_id: any;
  permission_on_resource: any;
};
